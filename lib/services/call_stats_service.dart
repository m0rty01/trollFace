import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class CallStatsService {
  final RTCPeerConnection _peerConnection;
  Timer? _statsTimer;

  CallStatsService(this._peerConnection);

  void startCollectingStats() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _collectStats();
    });
  }

  void stopCollectingStats() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<void> _collectStats() async {
    try {
      final stats = await _peerConnection.getStats();
      final videoStats = _getVideoStats(stats);
      final connectionStats = _getConnectionStats(stats);

      // Process and store stats as needed
      print('Video Stats: $videoStats');
      print('Connection Stats: $connectionStats');
    } catch (e) {
      print('Error collecting stats: $e');
    }
  }

  Map<String, double> _getVideoStats(RTCStatsReport stats) {
    final videoStats = <String, double>{};
    stats.forEach((key, value) {
      if (value.type == 'inbound-rtp' && value.mediaType == 'video') {
        videoStats['framesDropped'] = (value.framesDropped ?? 0).toDouble();
        videoStats['framesReceived'] = (value.framesReceived ?? 0).toDouble();
        videoStats['packetsLost'] = (value.packetsLost ?? 0).toDouble();
        videoStats['packetsReceived'] = (value.packetsReceived ?? 0).toDouble();
        videoStats['bytesReceived'] = (value.bytesReceived ?? 0).toDouble();
        videoStats['jitter'] = (value.jitter ?? 0).toDouble();
      }
    });
    return videoStats;
  }

  Map<String, double> _getConnectionStats(RTCStatsReport stats) {
    final connectionStats = <String, double>{};
    stats.forEach((key, value) {
      if (value.type == 'candidate-pair' && value.state == 'succeeded') {
        connectionStats['currentRoundTripTime'] = (value.currentRoundTripTime ?? 0).toDouble();
        connectionStats['availableOutgoingBitrate'] = (value.availableOutgoingBitrate ?? 0).toDouble();
        connectionStats['bytesReceived'] = (value.bytesReceived ?? 0).toDouble();
        connectionStats['bytesSent'] = (value.bytesSent ?? 0).toDouble();
      }
    });
    return connectionStats;
  }
} 