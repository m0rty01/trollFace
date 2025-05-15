import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionStateChanged;
  Function(ConnectionQuality)? onConnectionQualityChanged;

  late final Map<String, dynamic> _configuration;
  Map<String, dynamic> get configuration => _configuration;

  WebRTCService({
    this.onLocalStream,
    this.onRemoteStream,
    this.onConnectionStateChanged,
    this.onConnectionQualityChanged,
  });

  Future<void> initialize() async {
    _configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Add your TURN servers here if needed
      ],
      'sdpSemantics': 'unified-plan'
    };

    final constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    _peerConnection = await createPeerConnection(_configuration, constraints);
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer!.initialize();
    await _remoteRenderer!.initialize();

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      // Handle ICE candidate
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionStateChanged?.call(state);
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        _remoteRenderer?.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': 640,
        'height': 480,
      }
    });

    _localRenderer?.srcObject = _localStream;

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    onLocalStream?.call(_localStream!);
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection!.setRemoteDescription(description);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleCamera(bool isOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isOff;
    });
  }

  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      final currentFacingMode = videoTrack.getSettings()['facingMode'];
      final newFacingMode = currentFacingMode == 'user' ? 'environment' : 'user';
      
      final newStream = await navigator.mediaDevices.getUserMedia({
        'video': {
          'facingMode': newFacingMode,
        }
      });
      
      final newVideoTrack = newStream.getVideoTracks().first;
      final senders = await _peerConnection!.getSenders();
      final sender = senders.firstWhere(
        (s) => s.track?.kind == 'video',
      );
      
      await sender.replaceTrack(newVideoTrack);
      _localStream?.getVideoTracks().forEach((track) => track.stop());
      _localStream = newStream;
      onLocalStream?.call(_localStream!);
    }
  }

  Future<void> endCall() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    await _peerConnection?.close();
    await _localRenderer?.dispose();
    await _remoteRenderer?.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _localRenderer = null;
    _remoteRenderer = null;
  }

  void dispose() {
    endCall();
  }

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
}

enum ConnectionQuality {
  good,
  fair,
  poor,
  disconnected
} 