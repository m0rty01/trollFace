import 'dart:async';
import 'package:flutter/material.dart';
import 'call_stats_service.dart';

class CallQualityThresholds {
  static const double poorBitrate = 100.0; // kbps
  static const double poorLatency = 300.0; // ms
  static const double poorPacketLoss = 5.0; // %
  static const double poorFrameDrop = 10.0; // %
}

class CallQualityService {
  static final CallQualityService _instance = CallQualityService._internal();
  factory CallQualityService() => _instance;
  CallQualityService._internal();

  final _qualityController = StreamController<CallQuality>.broadcast();
  final _notificationController = StreamController<CallQualityNotification>.broadcast();
  final List<CallQuality> _qualityHistory = [];
  static const int maxHistoryPoints = 60; // 1 minute of history at 1-second intervals

  Stream<CallQuality> get qualityStream => _qualityController.stream;
  Stream<CallQualityNotification> get notificationStream => _notificationController.stream;
  List<CallQuality> get qualityHistory => List.unmodifiable(_qualityHistory);

  void startMonitoring(Stream<CallStats> statsStream) {
    statsStream.listen(_processStats);
  }

  void _processStats(CallStats stats) {
    final quality = _calculateQuality(stats);
    _qualityHistory.add(quality);
    if (_qualityHistory.length > maxHistoryPoints) {
      _qualityHistory.removeAt(0);
    }
    _qualityController.add(quality);
    _checkThresholds(quality);
  }

  CallQuality _calculateQuality(CallStats stats) {
    int score = 100;

    // Bitrate scoring (0-30 points)
    if (stats.bitrate < CallQualityThresholds.poorBitrate) {
      score -= 30;
    } else if (stats.bitrate < CallQualityThresholds.poorBitrate * 2) {
      score -= 15;
    }

    // Latency scoring (0-25 points)
    if (stats.latency > CallQualityThresholds.poorLatency) {
      score -= 25;
    } else if (stats.latency > CallQualityThresholds.poorLatency / 2) {
      score -= 12;
    }

    // Packet loss scoring (0-25 points)
    if (stats.packetLoss > CallQualityThresholds.poorPacketLoss) {
      score -= 25;
    } else if (stats.packetLoss > CallQualityThresholds.poorPacketLoss / 2) {
      score -= 12;
    }

    // Frame drop scoring (0-20 points)
    final frameDropRate = stats.frameDropRate * 100;
    if (frameDropRate > CallQualityThresholds.poorFrameDrop) {
      score -= 20;
    } else if (frameDropRate > CallQualityThresholds.poorFrameDrop / 2) {
      score -= 10;
    }

    return CallQuality(
      score: score,
      timestamp: DateTime.now(),
      stats: stats,
    );
  }

  void _checkThresholds(CallQuality quality) {
    if (quality.score < 50) {
      _notificationController.add(CallQualityNotification(
        type: NotificationType.poor,
        message: 'Call quality is poor. Consider switching to audio only.',
        quality: quality,
      ));
    } else if (quality.score < 70) {
      _notificationController.add(CallQualityNotification(
        type: NotificationType.warning,
        message: 'Call quality is degraded.',
        quality: quality,
      ));
    }
  }

  void dispose() {
    _qualityController.close();
    _notificationController.close();
  }
}

class CallQuality {
  final int score;
  final DateTime timestamp;
  final CallStats stats;

  CallQuality({
    required this.score,
    required this.timestamp,
    required this.stats,
  });

  bool get isGood => score >= 80;
  bool get isFair => score >= 60 && score < 80;
  bool get isPoor => score < 60;
}

class CallQualityNotification {
  final NotificationType type;
  final String message;
  final CallQuality quality;

  CallQualityNotification({
    required this.type,
    required this.message,
    required this.quality,
  });
}

enum NotificationType {
  warning,
  poor,
} 