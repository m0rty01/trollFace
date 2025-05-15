import 'package:supabase_flutter/supabase_flutter.dart';

class CallService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> startCall(String calleeId) async {
    final callerId = _supabase.auth.currentUser?.id;
    if (callerId == null) throw Exception('Not authenticated');
    final response = await _supabase
        .from('calls')
        .insert({
          'caller_id': callerId,
          'callee_id': calleeId,
          'status': 'ringing',
        })
        .select()
        .single();
    return response;
  }

  Stream<List<Map<String, dynamic>>> listenForIncomingCalls(String userId) {
    return _supabase
        .from('calls:callee_id=eq.$userId')
        .stream(primaryKey: ['id'])
        .eq('status', 'ringing');
  }

  Stream<Map<String, dynamic>?> listenForCallStatus(String callId) {
    return _supabase
        .from('calls:id=eq.$callId')
        .stream(primaryKey: ['id'])
        .map((calls) => calls.isNotEmpty ? calls.first : null);
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _supabase
        .from('calls')
        .update({'status': status})
        .eq('id', callId);
  }
} 