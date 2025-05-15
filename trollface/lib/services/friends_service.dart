import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getFriends() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('friends')
        .select('*, profiles:profiles!friends_user_id_fkey(*), friend_profile:profiles!friends_friend_id_fkey(*)')
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted');

    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('friends')
        .select('*, profiles!friends_user_id_fkey(*)')
        .eq('friend_id', userId)
        .eq('status', 'pending');

    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendFriendRequest(String friendId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('friends').insert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _supabase
        .from('friends')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _supabase.from('friends').delete().eq('id', requestId);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('email', '%$email%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();
    return response;
  }

  User? get currentUser => _supabase.auth.currentUser;
} 