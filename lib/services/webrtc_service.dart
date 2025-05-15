import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  final Function(MediaStream)? onLocalStream;
  final Function(MediaStream)? onRemoteStream;
  final Function(RTCPeerConnectionState)? onConnectionStateChange;

  WebRTCService({
    this.onLocalStream,
    this.onRemoteStream,
    this.onConnectionStateChange,
  }) {
    _initialize();
  }

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> _initialize() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      // Handle ICE candidate
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionStateChange?.call(state);
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _startReconnectTimer();
      } else {
        _stopReconnectTimer();
      }
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };
  }

  Future<void> startLocalStream() async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    onLocalStream?.call(_localStream!);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  Future<void> createOffer() async {
    try {
      final offer = await _peerConnection?.createOffer();
      await _peerConnection?.setLocalDescription(offer);
      // Send offer to remote peer
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<void> handleAnswer(RTCSessionDescription answer) async {
    try {
      await _peerConnection?.setRemoteDescription(answer);
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> handleCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (e) {
      print('Error handling candidate: $e');
    }
  }

  void toggleMute() {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !track.enabled;
    });
  }

  void toggleCamera() {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !track.enabled;
    });
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_reconnectAttempt < 3) {
        _reconnectAttempt++;
        _initialize();
      } else {
        _stopReconnectTimer();
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
  }

  void _handleSignalingMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'offer':
        handleAnswer(RTCSessionDescription(
          data['sdp'],
          data['type'],
        ));
        break;
      case 'answer':
        handleAnswer(RTCSessionDescription(
          data['sdp'],
          data['type'],
        ));
        break;
      case 'candidate':
        handleCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
        break;
    }
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
  }
} 