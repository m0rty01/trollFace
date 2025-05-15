import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../services/supabase_service.dart';
import '../services/call_stats_service.dart';
import '../services/audio_service.dart';
import '../models/face_filter.dart';
import '../widgets/face_filter_renderer.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final WebRTCService webRTCService;
  final SupabaseService supabaseService;
  final CallStatsService callStatsService;
  final AudioService audioService;

  const CallScreen({
    Key? key,
    required this.callId,
    required this.webRTCService,
    required this.supabaseService,
    required this.callStatsService,
    required this.audioService,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRTCService _webRTCService;
  late final SupabaseService _supabaseService;
  late final CallStatsService _callStatsService;
  late final AudioService _audioService;
  List<FaceFilter> _filters = [];
  FaceFilter? _selectedFilter;
  String? _currentFilterUsageId;

  @override
  void initState() {
    super.initState();
    _webRTCService = widget.webRTCService;
    _supabaseService = widget.supabaseService;
    _callStatsService = widget.callStatsService;
    _audioService = widget.audioService;
    _initializeFaceFilters();
  }

  void _initializeFaceFilters() {
    _filters = [
      FaceFilter(
        id: '1',
        name: 'Basic',
        style: FilterStyle(),
      ),
      // Add more filters here
    ];
  }

  List<FaceFilter> _getFilteredFilters() {
    return _filters;
  }

  void _showFilterCustomization(FaceFilter filter) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Customize ${filter.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              'Brightness',
              filter.style.brightness,
              (value) {
                setState(() {
                  _selectedFilter = filter.copyWith(
                    style: filter.style.copyWith(brightness: value),
                  );
                });
              },
            ),
            _buildSlider(
              'Contrast',
              filter.style.contrast,
              (value) {
                setState(() {
                  _selectedFilter = filter.copyWith(
                    style: filter.style.copyWith(contrast: value),
                  );
                });
              },
            ),
            _buildSlider(
              'Saturation',
              filter.style.saturation,
              (value) {
                setState(() {
                  _selectedFilter = filter.copyWith(
                    style: filter.style.copyWith(saturation: value),
                  );
                });
              },
            ),
            _buildSlider(
              'Opacity',
              filter.style.opacity,
              (value) {
                setState(() {
                  _selectedFilter = filter.copyWith(
                    style: filter.style.copyWith(opacity: value),
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedFilter != null) {
            _selectedFilter = _selectedFilter!.copyWith(
              style: _selectedFilter!.style.copyWith(tint: color),
            );
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedFilter?.style.tint == color
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _applyFilter(FaceFilter filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    if (_currentFilterUsageId != null) {
      await _supabaseService.endFilterUsage(_currentFilterUsageId!);
    }

    _currentFilterUsageId = await _supabaseService.logFilterUsage(
      filterName: filter.name,
      triggeredEffects: filter.triggerEffects,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video streams
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _webRTCService.localStream != null
                      ? RTCVideoView(
                          _webRTCService.localStream!.getRenderers().isNotEmpty
                              ? _webRTCService.localStream!.getRenderers().first
                              : RTCVideoRenderer(),
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(color: Colors.black),
                ),
                Expanded(
                  child: _webRTCService.remoteStream != null
                      ? RTCVideoView(
                          _webRTCService.remoteStream!.getRenderers().isNotEmpty
                              ? _webRTCService.remoteStream!.getRenderers().first
                              : RTCVideoRenderer(),
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(color: Colors.black),
                ),
              ],
            ),
          ),
          // Filter controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _getFilteredFilters().length,
                itemBuilder: (context, index) {
                  final filter = _getFilteredFilters()[index];
                  return GestureDetector(
                    onTap: () => _applyFilter(filter),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedFilter?.id == filter.id
                              ? Colors.blue
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(filter.name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Call controls
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _webRTCService.toggleMute(),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => _webRTCService.toggleCamera(),
                ),
                IconButton(
                  icon: const Icon(Icons.call_end),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_currentFilterUsageId != null) {
      _supabaseService.endFilterUsage(_currentFilterUsageId!);
    }
    super.dispose();
  }
} 