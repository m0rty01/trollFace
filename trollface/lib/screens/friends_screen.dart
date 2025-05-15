import 'package:flutter/material.dart';
import '../services/friends_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendsService.getFriends();
      final pendingRequests = await _friendsService.getPendingFriendRequests();
      print('DEBUG: friends = ' + friends.toString());
      print('DEBUG: pendingRequests = ' + pendingRequests.toString());
      setState(() {
        _friends = friends;
        _pendingRequests = pendingRequests;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading friends: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildPendingRequestsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Text('No friends yet'));
    }

    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendRow = _friends[index];
        final currentUserId = _friendsService.currentUser?.id;
        final isSender = friendRow['user_id'] == currentUserId;
        final friendProfile = isSender ? friendRow['friend_profile'] : friendRow['profiles'];
        if (friendProfile == null) {
          return const ListTile(
            title: Text('Unknown user'),
            subtitle: Text('This user no longer exists.'),
          );
        }
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              (friendProfile['username'] != null && friendProfile['username'].isNotEmpty)
                ? friendProfile['username'][0].toUpperCase()
                : (friendProfile['email'] != null && friendProfile['email'].isNotEmpty)
                  ? friendProfile['email'][0].toUpperCase()
                  : '?',
            ),
          ),
          title: Text(
            (friendProfile['username'] != null && friendProfile['username'].isNotEmpty)
              ? friendProfile['username']
              : (friendProfile['email'] ?? 'Unknown'),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () => _startVideoCall(friendProfile['id']),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsList() {
    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final sender = request['profiles'];
        if (sender == null) {
          return const ListTile(
            title: Text('Unknown user'),
            subtitle: Text('This user no longer exists.'),
          );
        }
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              (sender['username'] != null && sender['username'].isNotEmpty)
                ? sender['username'][0].toUpperCase()
                : (sender['email'] != null && sender['email'].isNotEmpty)
                  ? sender['email'][0].toUpperCase()
                  : '?',
            ),
          ),
          title: Text(
            (sender['username'] != null && sender['username'].isNotEmpty)
              ? sender['username']
              : (sender['email'] ?? 'Unknown'),
          ),
          subtitle: const Text('wants to be your friend'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _handleFriendRequest(request['id'], true),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _handleFriendRequest(request['id'], false),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleFriendRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await _friendsService.acceptFriendRequest(requestId);
      } else {
        await _friendsService.rejectFriendRequest(requestId);
      }
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling request: $e')),
      );
    }
  }

  Future<void> _showAddFriendDialog() async {
    final TextEditingController emailController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Friend by Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() { isLoading = true; errorMessage = null; });
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter an email.';
                          isLoading = false;
                        });
                        return;
                      }
                      final currentUser = _friendsService.currentUser;
                      if (currentUser != null && currentUser.email == email) {
                        setState(() {
                          errorMessage = 'You cannot add yourself.';
                          isLoading = false;
                        });
                        return;
                      }
                      final user = await _friendsService.getUserByEmail(email);
                      if (user == null) {
                        setState(() {
                          errorMessage = 'No user found with that email.';
                          isLoading = false;
                        });
                        return;
                      }
                      try {
                        await _friendsService.sendFriendRequest(user['id']);
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent!')),
                        );
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Failed to send request: $e';
                          isLoading = false;
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _startVideoCall(String friendId) {
    // Navigate to call screen with the friend's ID
    Navigator.pushNamed(
      context,
      '/call',
      arguments: {'friendId': friendId},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 