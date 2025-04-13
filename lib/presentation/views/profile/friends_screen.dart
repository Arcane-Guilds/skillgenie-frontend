import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/viewmodels/friend_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/friend_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to tab controller to reload data when tab changes
    _tabController.addListener(_handleTabChange);
    
    // Load data when the screen is first opened
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      print('Tab changed to: ${_tabController.index}');
      // Only reload if we haven't already loaded data for this tab
      if (_tabController.index == 0 && Provider.of<FriendViewModel>(context, listen: false).friends.isEmpty) {
        // Friends tab - reload friends only if empty
        print('Reloading friends list (was empty)');
        final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
        friendViewModel.loadFriends();
      } else if (_tabController.index == 1 && Provider.of<FriendViewModel>(context, listen: false).friendRequests == null) {
        // Requests tab - reload requests only if null
        print('Reloading friend requests (was null)');
        final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
        friendViewModel.loadFriendRequests();
      }
    }
  }

  Future<void> _loadData() async {
    print('Initial data loading - friends and requests');
    final friendViewModel = Provider.of<FriendViewModel>(context, listen: false);
    
    // Load both friends and friend requests
    await friendViewModel.loadFriends();
    await friendViewModel.loadFriendRequests();
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
          if (friendViewModel.isLoading && 
              friendViewModel.friends.isEmpty && 
              friendViewModel.friendRequests == null) {
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
                    onPressed: _loadData,
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
    // Don't force refresh on every build - this causes too many API calls
    // Only refresh if the list is empty
    if (!viewModel.isLoading && viewModel.friends.isEmpty && viewModel.errorMessage == null) {
      // Delay the call slightly to prevent multiple simultaneous calls
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) viewModel.loadFriends();
      });
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
              onPressed: () => viewModel.loadFriends(),
              child: const Text('Force Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadFriends,
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
    
    if (requests == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.received.isEmpty && requests.sent.isEmpty) {
      return const Center(
        child: Text('No friend requests'),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadFriendRequests,
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
              onAccept: () => viewModel.acceptFriendRequest(request.id),
              onReject: () => viewModel.rejectFriendRequest(request.id),
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
      trailing: trailing,
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
} 