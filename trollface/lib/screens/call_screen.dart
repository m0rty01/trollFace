import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/web_rtc_service.dart';
import '../services/audio_service.dart';
import '../services/call_stats_service.dart';
import '../services/call_quality_service.dart';
import '../services/filter_effects_service.dart';
import '../services/supabase_service.dart';
import '../widgets/call_quality_graph.dart';
import '../widgets/face_filter_renderer.dart';
import '../models/face_filter.dart';
import 'dart:async';
import '../services/filter_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final bool isIncoming;
  final SupabaseService supabaseService;
  final WebRTCService webRTCService;
  final CallStatsService callStatsService;
  final AudioService audioService;

  const CallScreen({
    Key? key,
    required this.callId,
    this.isIncoming = false,
    required this.supabaseService,
    required this.webRTCService,
    required this.callStatsService,
    required this.audioService,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Video renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  // Services
  late final WebRTCService _webRTCService;
  late final SupabaseService _supabaseService;
  late final CallStatsService _callStatsService;
  late final AudioService _audioService;
  late final CallQualityService _callQualityService;
  late final FilterEffectsService _filterEffectsService;
  late final FilterPreferences _filterPreferences;

  // State variables
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isReconnecting = false;
  int _reconnectAttempt = 0;
  CallStats? _currentStats;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;
  ConnectionQuality _connectionQuality = ConnectionQuality.good;
  List<FaceFilter> _activeFilters = [];
  FilterCategory? _selectedCategory;
  final Map<String, Timer> _filterTimers = {};
  DateTime? _callStartTime;
  final Map<String, DateTime> _filterStartTimes = {};
  String? _currentSessionId;
  Map<String, String> _activeFilterUsageIds = {};
  RTCPeerConnectionState _connectionState = RTCPeerConnectionState.RTCPeerConnectionStateNew;
  MediaStream? _remoteStream;
  MediaStream? _localStream;
  String? _callSessionId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeCall();
    _initializeFilterPreferences();
  }

  void _initializeServices() {
    _webRTCService = widget.webRTCService;
    _supabaseService = widget.supabaseService;
    _callStatsService = widget.callStatsService;
    _audioService = widget.audioService;
    _callQualityService = CallQualityService();
    _filterEffectsService = FilterEffectsService();

    _webRTCService.onRemoteStream = _handleRemoteStream;
    _webRTCService.onConnectionStateChanged = _handleConnectionStateChanged;
    _webRTCService.onConnectionQualityChanged = _handleConnectionQualityChanged;
    _callStartTime = DateTime.now();
  }

  void _handleRemoteStream(MediaStream stream) {
    setState(() {
      _remoteStream = stream;
    });
  }

  void _handleConnectionStateChanged(RTCPeerConnectionState state) {
    setState(() {
      _connectionState = state;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _isReconnecting = true;
        _reconnectAttempt++;
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _isReconnecting = false;
        _reconnectAttempt = 0;
      }
    });
  }

  void _handleConnectionQualityChanged(ConnectionQuality quality) {
    setState(() {
      _connectionQuality = quality;
    });
  }

  Future<void> _initializeFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _filterPreferences = FilterPreferences(prefs);
    final savedFilters = await _filterPreferences.loadActiveFilters();
    if (savedFilters.isNotEmpty) {
      setState(() {
        _activeFilters = savedFilters;
      });
    } else {
      _initializeDefaultFilters();
    }
  }

  void _initializeDefaultFilters() {
    setState(() {
      _activeFilters = [
        FaceFilter.predefined[0], // Glasses
        FaceFilter.predefined[1], // Mustache
      ];
    });
  }

  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    widget.webRTCService.onLocalStream = (stream) {
      setState(() {
        _localStream = stream;
        _localRenderer.srcObject = stream;
      });
    };

    widget.webRTCService.onRemoteStream = (stream) {
      setState(() {
        _remoteStream = stream;
        _remoteRenderer.srcObject = stream;
      });
    };

    widget.webRTCService.onConnectionStateChanged = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _logCallSession();
      }
    };

    widget.webRTCService.onConnectionQualityChanged = (quality) {
      setState(() {
        _connectionQuality = quality;
      });
    };

    await widget.webRTCService.initialize();
    widget.callStatsService.startMonitoring(widget.webRTCService.peerConnection!);
  }

  Future<void> _logCallSession() async {
    if (_callSessionId == null) {
      final response = await widget.supabaseService.logCallSession(
        startTime: DateTime.now(),
        usedTurn: widget.webRTCService.configuration['iceServers']?.isNotEmpty ?? false,
      );
      _callSessionId = response;
    }
  }

  // Call control methods
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _webRTCService.toggleMute(_isMuted);
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
      _webRTCService.toggleCamera(_isCameraOff);
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _audioService.setSpeaker(_isSpeakerOn);
  }

  void _switchCamera() {
    _webRTCService.switchCamera();
  }

  // Filter control methods
  void _toggleFilter(FaceFilter filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
        _endFilterUsage(filter);
      } else {
        _activeFilters.add(filter);
        _startFilterUsage(filter);
      }
    });
  }

  Future<void> _startFilterUsage(FaceFilter filter) async {
    if (_callSessionId != null) {
      final response = await widget.supabaseService.logFilterUsage(
        sessionId: _callSessionId!,
        filterId: filter.name,
        startTime: DateTime.now(),
        triggerEffects: filter.triggerEffects.toList(),
      );
      setState(() {
        _activeFilterUsageIds[filter.name] = response;
      });
    }
  }

  Future<void> _endFilterUsage(FaceFilter filter) async {
    if (_activeFilterUsageIds.containsKey(filter.name)) {
      await widget.supabaseService.endFilterUsage(
        usageId: _activeFilterUsageIds[filter.name]!,
        endTime: DateTime.now(),
      );
      setState(() {
        _activeFilterUsageIds.remove(filter.name);
      });
    }
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    await _logCallData();
    await _logActiveFilters();
    await _webRTCService.endCall();
    
    if (_currentSessionId != null) {
      await widget.supabaseService.endCallSession(_currentSessionId!);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _logCallData() async {
    if (_callSessionId != null) {
      await widget.supabaseService.logCallData(
        sessionId: _callSessionId!,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        duration: const Duration(minutes: 5).inSeconds,
        activeFilters: _activeFilterUsageIds.keys.toList(),
        bitrate: 1000,
        latency: 50,
        packetLoss: 0.5,
        frameDropRate: 0.1,
      );
    }
  }

  Future<void> _logActiveFilters() async {
    for (final filterId in _activeFilterUsageIds.keys) {
      await widget.supabaseService.logFilterUsage(
        sessionId: _callSessionId!,
        filterId: filterId,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        triggerEffects: ['onEnd'],
      );
    }
  }

  // UI helper methods
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  Color _getConnectionQualityColor() {
    switch (_connectionQuality) {
      case ConnectionQuality.good:
        return Colors.green;
      case ConnectionQuality.fair:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.disconnected:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _webRTCService.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _callStatsService.dispose();
    _filterEffectsService.dispose();
    _filterTimers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          Positioned(
            right: 20,
            top: 40,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 28,
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.yellow,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        widget.webRTCService.toggleMute(_isMuted);
                      });
                    },
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 28,
                  child: IconButton(
                    icon: Icon(
                      _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: Colors.yellow,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCameraOff = !_isCameraOff;
                        widget.webRTCService.toggleCamera(_isCameraOff);
                      });
                    },
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 28,
                  child: IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: Colors.yellow,
                      size: 30,
                    ),
                    onPressed: _toggleSpeaker,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 28,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.yellow,
                      size: 30,
                    ),
                    onPressed: _switchCamera,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 28,
                  child: IconButton(
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 30,
                    ),
                    onPressed: () async {
                      await _logCallData();
                      await _logActiveFilters();
                      widget.webRTCService.endCall();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 