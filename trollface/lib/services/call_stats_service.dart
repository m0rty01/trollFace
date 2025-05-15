import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class CallStats {
  final double bitrate;
  final double latency;
  final double packetLoss;
  final double frameDropRate;

  CallStats({
    required this.bitrate,
    required this.latency,
    required this.packetLoss,
    required this.frameDropRate,
  });
}

class CallStatsService {
  static final CallStatsService _instance = CallStatsService._internal();
  factory CallStatsService() => _instance;
  CallStatsService._internal();

  final _statsController = StreamController<CallStats>.broadcast();
  Timer? _statsTimer;
  RTCPeerConnection? _peerConnection;

  Stream<CallStats> get statsStream => _statsController.stream;

  void startMonitoring(RTCPeerConnection peerConnection) {
    _peerConnection = peerConnection;
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final stats = await peerConnection.getStats();
        double bitrate = 0;
        double latency = 0;
        double packetLoss = 0;
        double frameDropRate = 0;

        stats.forEach((report) {
          if (report.type == 'inbound-rtp' && report.values['mediaType'] == 'video') {
            bitrate = (report.values['bytesReceived'] ?? 0) * 8 / 1000; // Convert to kbps
            frameDropRate = (report.values['framesDropped'] ?? 0) / 
                          (report.values['framesReceived'] ?? 1);
          }
          if (report.type == 'candidate-pair' && report.values['state'] == 'succeeded') {
            latency = report.values['currentRoundTripTime'] ?? 0;
            packetLoss = (report.values['packetsLost'] ?? 0) / 
                        (report.values['packetsSent'] ?? 1) * 100;
          }
        });

        _statsController.add(CallStats(
          bitrate: bitrate,
          latency: latency,
          packetLoss: packetLoss,
          frameDropRate: frameDropRate,
        ));
      } catch (e) {
        print('Error getting stats: $e');
      }
    });
  }

  void dispose() {
    _statsTimer?.cancel();
    _statsController.close();
  }
} 