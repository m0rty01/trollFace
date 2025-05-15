import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/face_filter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<Map<String, dynamic>> getFilterUsageStats() async {
    try {
      final response = await _client
          .from('filter_usage')
          .select('filter_name, count:filter_name')
          .execute();
      final data = response.data as List<dynamic>? ?? [];
      return {
        'total_usage': data.fold<int>(
            0, (sum, item) => sum + (item['count'] as int? ?? 0)),
        'filters': data.map((item) => {
              'name': item['filter_name'],
              'count': item['count'],
            }).toList(),
      };
    } catch (e) {
      print('Error getting filter usage stats: $e');
      return {
        'total_usage': 0,
        'filters': [],
      };
    }
  }

  Future<String> logFilterUsage({
    required String filterName,
    List<String>? triggeredEffects,
  }) async {
    try {
      final response = await _client.from('filter_usage').insert({
        'filter_name': filterName,
        'triggered_effects': triggeredEffects,
        'start_time': DateTime.now().toIso8601String(),
      }).select('id').single();
      return response['id'] as String;
    } catch (e) {
      print('Error logging filter usage: $e');
      return '';
    }
  }

  Future<void> endFilterUsage(String usageId) async {
    try {
      await _client.from('filter_usage').update({
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', usageId);
    } catch (e) {
      print('Error ending filter usage: $e');
    }
  }

  Future<void> saveFilterStyle(String filterId, FilterStyle style) async {
    try {
      await _client.from('filter_styles').upsert({
        'filter_id': filterId,
        'style': style.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving filter style: $e');
    }
  }

  Future<FilterStyle?> getFilterStyle(String filterId) async {
    try {
      final response = await _client
          .from('filter_styles')
          .select('style')
          .eq('filter_id', filterId)
          .maybeSingle();
      if (response != null && response['style'] != null) {
        return FilterStyle.fromMap(Map<String, dynamic>.from(response['style']));
      }
      return null;
    } catch (e) {
      print('Error getting filter style: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCallQualityStats(DateTime since) async {
    try {
      final response = await _client
          .from('call_stats')
          .select('*')
          .where('timestamp', isGreaterThan: since.toIso8601String())
          .execute();
      final data = response.data as List<dynamic>? ?? [];
      return data.map((item) => {
        'video': {
          'framesDropped': item['frames_dropped'] ?? 0,
          'framesReceived': item['frames_received'] ?? 0,
          'packetsLost': item['packets_lost'] ?? 0,
          'packetsReceived': item['packets_received'] ?? 0,
          'bytesReceived': item['bytes_received'] ?? 0,
          'jitter': item['jitter'] ?? 0.0,
        },
        'connection': {
          'currentRoundTripTime': item['rtt'] ?? 0.0,
          'availableOutgoingBitrate': item['bitrate'] ?? 0.0,
          'bytesReceived': item['bytes_received'] ?? 0,
          'bytesSent': item['bytes_sent'] ?? 0,
        },
      }).toList();
    } catch (e) {
      print('Error getting call quality stats: $e');
      return [];
    }
  }
} 