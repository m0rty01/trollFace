import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/face_filter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  final SupabaseClient client;

  factory SupabaseService() => _instance;

  SupabaseService._internal() : client = Supabase.instance.client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  }

  Future<void> logCall({
    required String callId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required List<String> activeFilters,
    required Map<String, dynamic> callStats,
  }) async {
    await client.from('call_history').insert({
      'call_id': callId,
      'user_id': userId ?? '',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration.inSeconds,
      'active_filters': activeFilters,
      'call_stats': callStats,
    });
  }

  Future<String> logCallSession({
    required DateTime startTime,
    required bool usedTurn,
  }) async {
    final response = await client
        .from('call_sessions')
        .insert({
          'start_time': startTime.toIso8601String(),
          'used_turn': usedTurn,
          'user_id': client.auth.currentUser?.id ?? '',
        })
        .select()
        .single();
    
    return response['id'] as String;
  }

  Future<String> logFilterUsage({
    required String sessionId,
    required String filterId,
    required DateTime startTime,
    required List<String> triggerEffects,
  }) async {
    final response = await client
        .from('filter_usage')
        .insert({
          'session_id': sessionId,
          'filter_id': filterId,
          'start_time': startTime.toIso8601String(),
          'trigger_effects': triggerEffects,
        })
        .select()
        .single();
    
    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getCallHistory(String userId) async {
    final response = await client
        .from('call_history')
        .select()
        .eq('user_id', userId ?? '')
        .order('start_time', ascending: false)
        .limit(50);
    return response;
  }

  Future<List<Map<String, dynamic>>> getPopularFilters() async {
    final response = await client
        .from('filter_usage')
        .select('filter_id, count')
        .order('count', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getUserStats(String? userId) async {
    final response = await client
        .from('call_history')
        .select('duration, active_filters')
        .eq('user_id', userId ?? '');
    
    int totalDuration = 0;
    Map<String, int> filterCounts = {};

    for (var record in response) {
      totalDuration += record['duration'] as int;
      final filters = List<String>.from(record['active_filters'] as List);
      for (var filter in filters) {
        filterCounts[filter] = (filterCounts[filter] ?? 0) + 1;
      }
    }

    return {
      'total_duration': totalDuration,
      'filter_counts': filterCounts,
    };
  }

  // Get recent call history for a user
  Future<List<Map<String, dynamic>>> getRecentCallHistory() async {
    final response = await client
        .from('call_sessions')
        .select()
        .eq('user_id', client.auth.currentUser?.id ?? '')
        .order('start_time', ascending: false)
        .limit(10);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Get filter usage statistics for a user
  Future<Map<String, dynamic>> getUserFilterStats() async {
    final response = await client
        .from('filter_usage')
        .select('filter_id, count')
        .eq('user_id', client.auth.currentUser?.id ?? '')
        .order('count', ascending: false);
    
    return Map<String, dynamic>.from(response.first);
  }

  // Get call quality statistics
  Future<Map<String, dynamic>> getCallQualityStats({
    DateTime? since,
  }) async {
    try {
      final query = client
          .from('call_history')
          .select('''
            avg(call_stats.bitrate),
            avg(call_stats.latency),
            avg(call_stats.packet_loss),
            avg(call_stats.frame_drop_rate),
            count(distinct call_id)
          ''')
          .eq('user_id', client.auth.currentUser?.id ?? '');

      if (since != null) {
        query.gte('start_time', since.toIso8601String());
      }

      final response = await query;
      return response.first;
    } catch (e) {
      debugPrint('Error fetching call quality stats: $e');
      rethrow;
    }
  }

  // Get detailed call quality statistics for a specific time period
  Future<Map<String, dynamic>> getDetailedCallQualityStats(DateTime since) async {
    final response = await client
      .from('call_history')
      .select('call_stats, start_time')
      .gte('start_time', since.toIso8601String())
      .eq('user_id', client.auth.currentUser?.id ?? '');
    
    return {
      'stats': response,
      'period': since.toIso8601String(),
    };
  }

  // End a call session
  Future<void> endCallSession(String sessionId) async {
    final endTime = DateTime.now();
    await client.from('call_sessions')
      .update({
        'end_time': endTime.toIso8601String(),
        'duration': endTime.difference(DateTime.parse(
          (await client.from('call_sessions')
            .select('start_time')
            .eq('id', sessionId)
            .single())['start_time']
        )).inSeconds,
      })
      .eq('id', sessionId);
  }

  // End filter usage
  Future<void> endFilterUsage({
    required String usageId,
    required DateTime endTime,
  }) async {
    await client
        .from('filter_usage')
        .update({
          'end_time': endTime.toIso8601String(),
        })
        .eq('id', usageId);
  }

  // Log call quality metrics
  Future<void> logCallQuality({
    required String sessionId,
    required int bitrate,
    required int latency,
    required double packetLoss,
    required double frameDropRate,
  }) async {
    try {
      await client.from('call_history').insert({
        'call_id': sessionId,
        'user_id': client.auth.currentUser?.id ?? '',
        'start_time': DateTime.now().toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'duration': 0,
        'active_filters': [],
        'call_stats': {
          'bitrate': bitrate,
          'latency': latency,
          'packet_loss': packetLoss,
          'frame_drop_rate': frameDropRate,
        },
      });
    } catch (e) {
      debugPrint('Error logging call quality: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilterStats(DateTime since) async {
    final response = await client
        .from('filter_usage')
        .select('filter_name, count')
        .gte('start_time', since.toIso8601String())
        .eq('user_id', client.auth.currentUser?.id ?? '')
        .order('count', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> logCallData({
    required String sessionId,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    required List<String> activeFilters,
    required double bitrate,
    required double latency,
    required double packetLoss,
    required double frameDropRate,
  }) async {
    await client
        .from('call_data')
        .insert({
          'session_id': sessionId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'duration': duration,
          'active_filters': activeFilters,
          'bitrate': bitrate,
          'latency': latency,
          'packet_loss': packetLoss,
          'frame_drop_rate': frameDropRate,
        });
  }
} 