import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/viewmodels/friend_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/friend_model.dart';
import '../../../presentation/viewmodels/chat_viewmodel.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/auth/auth_viewmodel.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _initialDataLoaded = false;
  DateTime _lastFriendsLoad = DateTime(1970);
  DateTime _lastRequestsLoad = DateTime(1970);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to tab controller to reload data when tab changes
    _tabController.addListener(_handleTabChange);
    
    // Only load initial data once when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialDataLoaded) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Handle tab changes with throttling to prevent excessive API calls
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      print('Tab changed to: ${_tabController.index}');
      final now = DateTime.now();
      
      if (_tabController.index == 0) {
        // Only reload friends if it's been at least 30 seconds since last load
        if (now.difference(_lastFriendsLoad).inSeconds > 30) {
          print('Loading friends data (tab change)');
          _lastFriendsLoad = now;
          Provider.of<FriendViewModel>(context, listen: false).loadFriends();
        } else {
          print('Skipping friends reload - loaded recently');
        }
      } else if (_tabController.index == 1) {
        // Only reload requests if it's been at least 30 seconds since last load  
        if (now.difference(_lastRequestsLoad).inSeconds > 30) {
          print('Loading friend requests (tab change)');
          _lastRequestsLoad = now;
          Provider.of<FriendViewModel>(context, listen: false).loadFriendRequests();
        } else {
          print('Skipping requests reload - loaded recently');
        }
      }
    }
  }

  // Load initial data only once
  Future<void> _loadInitialData() async {
    print('Initial data loading - friends and requests');
    final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
    
    _initialDataLoaded = true;
    _lastFriendsLoad = DateTime.now();
    _lastRequestsLoad = DateTime.now();
    
    // Load both friends and friend requests
    await friendViewModel.loadFriends();
    
    // Small delay to prevent hammering the server with multiple requests at once
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      await friendViewModel.loadFriendRequests();
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
            Tab(text: 'Add Friends'),
          ],
        ),
      ),
      body: Consumer<FriendViewModel>(
        builder: (context, friendViewModel, child) {
          if (!_initialDataLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendViewModel.errorMessage != null &&
              friendViewModel.friends.isEmpty &&
              friendViewModel.friendRequests == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${friendViewModel.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _lastFriendsLoad = DateTime.now();
                      _lastRequestsLoad = DateTime.now();
                      friendViewModel.loadFriends();
                      friendViewModel.loadFriendRequests();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(friendViewModel),
              _buildRequestsTab(friendViewModel),
              _buildAddFriendsTab(friendViewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab(FriendViewModel viewModel) {
    // Don't reload data on every build
    // This forces a refresh only if friends list is empty AND no loading is in progress
    if (!viewModel.isLoading && 
        viewModel.friends.isEmpty && 
        viewModel.errorMessage == null &&
        DateTime.now().difference(_lastFriendsLoad).inSeconds > 5) {
      
      _lastFriendsLoad = DateTime.now();
      // Use a small delay to prevent multiple calls if widget rebuilds rapidly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) viewModel.loadFriends();
      });
    }
    
    if (viewModel.isLoading && viewModel.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewModel.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have any friends yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to "Add Friends" to find new people',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('Add Friends'),
            ),
            const SizedBox(height: 8),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Error: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _lastFriendsLoad = DateTime.now();
                viewModel.loadFriends();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _lastFriendsLoad = DateTime.now();
        return viewModel.loadFriends();
      },
      child: ListView.builder(
        itemCount: viewModel.friends.length,
        itemBuilder: (context, index) {
          final friend = viewModel.friends[index];
          return _buildUserListTile(
            user: friend,
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _showRemoveFriendDialog(friend),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(FriendViewModel viewModel) {
    final requests = viewModel.friendRequests;
    
    // Only reload if we've waited a reasonable time since last load
    if (requests == null && 
        !viewModel.isLoading && 
        DateTime.now().difference(_lastRequestsLoad).inSeconds > 5) {
      _lastRequestsLoad = DateTime.now();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) viewModel.loadFriendRequests();
      });
    }
    
    if (viewModel.isLoading && requests == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests == null) {
      return const Center(child: Text('Loading requests...'));
    }

    if (requests.received.isEmpty && requests.sent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No friend requests', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _lastRequestsLoad = DateTime.now();
                viewModel.loadFriendRequests();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _lastRequestsLoad = DateTime.now();
        return viewModel.loadFriendRequests();
      },
      child: ListView(
        children: [
          if (requests.received.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Incoming Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...requests.received.map((request) => _buildRequestTile(
              request: request,
              isReceived: true,
              onAccept: () => _handleFriendRequestAccept(request),
              onReject: () => _handleFriendRequestReject(request.id),
            )),
          ],
          
          if (requests.sent.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sent Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...requests.sent.map((request) => _buildRequestTile(
              request: request,
              isReceived: false,
              onAccept: null,
              onReject: null,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAddFriendsTab(FriendViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearSearchResults();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    viewModel.searchUsers(_searchController.text);
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: viewModel.isLoading && viewModel.searchResults.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : viewModel.searchResults.isEmpty
                  ? const Center(
                      child: Text('Search for users to add as friends'),
                    )
                  : ListView.builder(
                      itemCount: viewModel.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = viewModel.searchResults[index];
                        return _buildUserListTile(
                          user: user,
                          trailing: ElevatedButton(
                            onPressed: () => viewModel.sendFriendRequest(user.id),
                            child: const Text('Send Request'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserListTile({
    required User user,
    required Widget trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatar != null
            ? NetworkImage(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(user.username),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.blue),
            tooltip: 'Message',
            onPressed: () => _startChatWithUser(user),
          ),
          trailing,
        ],
      ),
      onTap: () => _showUserOptions(user),
    );
  }

  Widget _buildRequestTile({
    required FriendRequest request,
    required bool isReceived,
    required Function()? onAccept,
    required Function()? onReject,
  }) {
    final user = isReceived ? request.sender : request.receiver;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatar != null
            ? NetworkImage(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(user.username),
      subtitle: Text(isReceived ? 'Wants to be your friend' : 'Request sent'),
      trailing: isReceived
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: onAccept,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onReject,
                ),
              ],
            )
          : const Text('Pending'),
    );
  }

  void _showRemoveFriendDialog(User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.username} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final viewModel = Provider.of<FriendViewModel>(context, listen: false);
              viewModel.removeFriend(friend.id);
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _startChatWithUser(User user) async {
    // Navigate to chat screen with this user
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    try {
      // First check if the user is authenticated
      if (!authViewModel.isAuthenticated) {
        print('Chat error: User is not authenticated');
        throw Exception('You need to be logged in to start a chat');
      }
      
      // Additional validation of token
      if (authViewModel.tokens == null || 
          authViewModel.tokens!.accessToken.isEmpty) {
        print('Chat error: Invalid or missing token');
        throw Exception('Authentication token is missing or invalid');
      }
      
      print('Starting chat with user: ${user.username} (${user.id})');
      print('Current user ID: ${authViewModel.userId}');
      print('Access token available (first 10 chars): ${authViewModel.tokens!.accessToken.substring(0, 10)}...');
      
      // Verify token is in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final tokenInPrefs = prefs.getString('accessToken');
      if (tokenInPrefs == null) {
        print('WARNING: Token not found in SharedPreferences, refreshing auth status');
        await authViewModel.checkAuthStatus();
        
        // If still not authenticated after refresh, throw error
        if (!authViewModel.isAuthenticated) {
          throw Exception('Authentication failed after refresh');
        }
      }
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text('Opening chat with ${user.username}...'),
            ],
          ),
        ),
      );
      
      // Find or create a chat with this user
      final chatId = await chatViewModel.findOrCreateDirectChat(user.id);
      
      if (mounted && chatId != null) {
        print('Chat found/created successfully with ID: $chatId');
        GoRouter.of(context).push('/chat/detail', extra: chatId);
      } else {
        throw Exception('Failed to open chat: Chat ID is null');
      }
    } catch (e) {
      if (mounted) {
        print('Chat creation error: $e');
        
        // Show a more detailed message depending on the error
        String errorMessage = 'Failed to start chat: $e';
        
        if (e.toString().contains('401') || e.toString().contains('Authentication failed')) {
          errorMessage = 'Authentication error. Please log out and log in again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 8),
            action: e.toString().contains('Authentication') ? 
              SnackBarAction(
                label: 'Log out',
                onPressed: () {
                  authViewModel.signOut().then((_) {
                    GoRouter.of(context).go('/login');
                  });
                },
              ) : null,
          ),
        );
      }
    }
  }

  void _showUserOptions(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user.avatar != null
                  ? NetworkImage(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              icon: Icons.chat,
              label: 'Send Message',
              onTap: () {
                Navigator.pop(context);
                _startChatWithUser(user);
              },
            ),
            _buildActionButton(
              icon: Icons.person_add,
              label: 'Send Friend Request',
              onTap: () {
                Navigator.pop(context);
                final viewModel = Provider.of<FriendViewModel>(context, listen: false);
                viewModel.sendFriendRequest(user.id);
              },
            ),
            _buildActionButton(
              icon: Icons.block,
              label: 'Block User',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block user functionality not implemented yet')),
                );
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  // Handle friend request acceptance with immediate UI feedback
  Future<void> _handleFriendRequestAccept(FriendRequest request) async {
    final viewModel = Provider.of<FriendViewModel>(context, listen: false);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text('Adding ${request.sender.username} as friend...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    try {
      await viewModel.acceptFriendRequest(request.id);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.sender.username} is now your friend!'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force update on UI by manually updating timestamps 
        // and switching to friends tab to show the new friend
        setState(() {
          _lastFriendsLoad = DateTime(1970);
          _lastRequestsLoad = DateTime(1970);
          _tabController.animateTo(0); // Switch to Friends tab
        });
      }
    } catch (e) {
      // Show error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle friend request rejection with immediate UI feedback
  Future<void> _handleFriendRequestReject(String requestId) async {
    final viewModel = Provider.of<FriendViewModel>(context, listen: false);
    
    try {
      await viewModel.rejectFriendRequest(requestId);
      
      // Force update on UI
      setState(() {
        _lastRequestsLoad = DateTime(1970);
      });
    } catch (e) {
      // Show error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 