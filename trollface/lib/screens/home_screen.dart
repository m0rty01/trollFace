import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/call_history.dart';
import '../models/friend.dart';
import '../services/signaling_service.dart';
import 'call_screen.dart';
import 'package:uuid/uuid.dart';
import '../services/web_rtc_service.dart';
import '../services/supabase_service.dart';
import '../services/call_stats_service.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _signalingService = SignalingService();
  final _supabase = Supabase.instance.client;
  List<CallHistory> _recentCalls = [];
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadRecentCalls(),
        _loadFriends(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentCalls() async {
    try {
      final response = await _supabase
          .from('call_history')
          .select()
          .order('start_time', ascending: false)
          .limit(10);
      setState(() {
        _recentCalls = response.map((json) => CallHistory.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading recent calls: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final response = await _supabase
          .from('friends')
          .select()
          .order('name');
      setState(() {
        _friends = response.map((json) => Friend.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  Future<void> _startCall() async {
    try {
      final callId = const Uuid().v4();
      if (!mounted) return;
      
      final webRTCService = WebRTCService();
      final supabaseService = SupabaseService();
      final callStatsService = CallStatsService();
      final audioService = AudioService();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            callId: callId,
            isIncoming: false,
            supabaseService: supabaseService,
            webRTCService: webRTCService,
            callStatsService: callStatsService,
            audioService: audioService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start call: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _supabase.auth.currentUser;

    // Debug prints
    print('DEBUG: _friends.length = \'${_friends.length}\'' );
    print('DEBUG: _recentCalls.length = \'${_recentCalls.length}\'' );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrollFace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'DEBUG: HomeScreen loaded',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        print('DEBUG: Test button pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('TEST BUTTON (should always be visible)'),
                    ),
                    const SizedBox(height: 24),
                    _buildUserProfile(user),
                    const SizedBox(height: 24),
                    _buildStartCallButton(),
                    const SizedBox(height: 24),
                    _buildFriendsList(),
                    const SizedBox(height: 24),
                    _buildRecentCalls(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserProfile(User? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: user?.userMetadata?['avatar_url'] != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user!.userMetadata!['avatar_url'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.person),
                  ),
                )
              : Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.email ?? 'User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Online',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartCallButton() {
    return ElevatedButton.icon(
      onPressed: _startCall,
      icon: const Icon(Icons.video_call, color: Colors.white),
      label: const Text('Start Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('No friends found. Add some friends to get started!', style: TextStyle(color: Colors.deepPurple.shade200)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Friends',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              final friend = _friends[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.deepPurple,
                          child: friend.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: friend.avatarUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                                  ),
                                )
                              : Text(
                                  friend.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        if (friend.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(friend.name, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCalls() {
    if (_recentCalls.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Calls',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('No recent calls yet.', style: TextStyle(color: Colors.deepPurple.shade200)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Calls',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentCalls.length,
          itemBuilder: (context, index) {
            final call = _recentCalls[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCallStatusColor(call.status),
                child: Icon(
                  _getCallStatusIcon(call.status),
                  color: Colors.white,
                ),
              ),
              title: Text(call.receiverId ?? 'Unknown', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              subtitle: Text(
                DateFormat.yMMMd().add_jm().format(call.startTime),
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: Text(
                _getCallDuration(call),
                style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getCallStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.call;
      case 'missed':
        return Icons.call_missed;
      case 'ongoing':
        return Icons.call_received;
      default:
        return Icons.call;
    }
  }

  String _getCallDuration(CallHistory call) {
    if (call.endTime == null) return 'Ongoing';
    
    final duration = call.endTime!.difference(call.startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
} 