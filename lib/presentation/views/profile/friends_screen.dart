import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/viewmodels/friend_viewmodel.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/friend_model.dart';
import '../../../presentation/viewmodels/chat_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../widgets/avatar_widget.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _friendSearchController = TextEditingController(); // Controller for friends tab search
  bool _initialDataLoaded = false;
  DateTime _lastFriendsLoad = DateTime(1970);
  DateTime _lastRequestsLoad = DateTime(1970);
  String _friendSearchQuery = ''; // State variable to hold the friend search query

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to tab controller to reload data when tab changes
    _tabController.addListener(_handleTabChange);

    // Listener for friend search controller
    _friendSearchController.addListener(() {
      setState(() {
        _friendSearchQuery = _friendSearchController.text;
      });
    });

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
    _friendSearchController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Handle tab changes with throttling to prevent excessive API calls
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final now = DateTime.now();

      if (_tabController.index == 0) {
        // Only reload friends if it's been at least 30 seconds since last load
        if (now.difference(_lastFriendsLoad).inSeconds > 30) {
          _lastFriendsLoad = now;
          Provider.of<FriendViewModel>(context, listen: false).loadFriends();
        }
      } else if (_tabController.index == 1) {
        // Only reload requests if it's been at least 30 seconds since last load  
        if (now.difference(_lastRequestsLoad).inSeconds > 30) {
          _lastRequestsLoad = now;
          Provider.of<FriendViewModel>(context, listen: false).loadFriendRequests();
        }
      }
    }
  }

  // Load initial data only once
  Future<void> _loadInitialData() async {
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 3.0,
                  ),
                ),
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Friends'),
                Tab(text: 'Requests'),
                Tab(text: 'Add Friends'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Consumer<FriendViewModel>(
          builder: (context, friendViewModel, child) {
            if (!_initialDataLoaded) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            if (friendViewModel.errorMessage != null &&
                friendViewModel.friends.isEmpty &&
                friendViewModel.friendRequests == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${friendViewModel.errorMessage}',
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _lastFriendsLoad = DateTime.now();
                        _lastRequestsLoad = DateTime.now();
                        friendViewModel.loadFriends();
                        friendViewModel.loadFriendRequests();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildFriendsTab(FriendViewModel viewModel) {
    // Filter friends based on the search query
    final filteredFriends = viewModel.friends.where((friend) {
      final query = _friendSearchQuery.toLowerCase();
      if (query.isEmpty) {
        return true; // Show all if query is empty
      }
      return friend.username.toLowerCase().contains(query) ||
          friend.email.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Add Search Bar for Friends
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _friendSearchController,
              decoration: InputDecoration(
                hintText: 'Search your friends...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _friendSearchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _friendSearchController.clear();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),

        // Existing RefreshIndicator and ListView
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () {
              _lastFriendsLoad = DateTime.now();
              // Clear search when refreshing
              _friendSearchController.clear();
              return viewModel.loadFriends();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16), // Adjust padding
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                // Using the extracted _buildUserCard for consistency, but modifying actions
                return _buildFriendCard(viewModel, friend);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Card specifically for the friends list with chat/remove actions
  Widget _buildFriendCard(FriendViewModel viewModel, User friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserOptions(friend), // Keep showing options on tap
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: friend.avatar != null && friend.avatar!.isNotEmpty
                    ? (friend.avatar!.startsWith('http')
                    ? NetworkImage(friend.avatar!)
                    : AssetImage('assets/images/${friend.avatar}.png'))
                    : null,
                child: friend.avatar == null || friend.avatar!.isEmpty
                    ? Text(
                  friend.username.isNotEmpty
                      ? friend.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
                    : null,
              ),

              const SizedBox(width: 16),

              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chat button
                  Material(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _startChatWithUser(friend),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Remove button
                  Material(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showRemoveFriendDialog(friend),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.person_remove_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (requests == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Loading requests...'),
          ],
        ),
      );
    }

    if (requests.received.isEmpty && requests.sent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GenieAvatar(
              state: AvatarState.idle,
              size: 100,
              message: "No friend requests",
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending friend requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'When someone sends you a request, it will appear here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              onPressed: () {
                _lastRequestsLoad = DateTime.now();
                viewModel.loadFriendRequests();
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () {
        _lastRequestsLoad = DateTime.now();
        return viewModel.loadFriendRequests();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (requests.received.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Incoming Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ...requests.received.map((request) => _buildIncomingRequestCard(request)),
              const SizedBox(height: 24),
            ],

            if (requests.sent.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'Sent Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              ...requests.sent.map((request) => _buildSentRequestCard(request)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequestCard(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: request.sender.avatar != null && request.sender.avatar!.isNotEmpty
                      ? (request.sender.avatar!.startsWith('http')
                      ? NetworkImage(request.sender.avatar!)
                      : AssetImage('assets/images/${request.sender.avatar}.png'))
                      : null,
                  child: request.sender.avatar == null || request.sender.avatar!.isEmpty
                      ? Text(
                    request.sender.username.isNotEmpty
                        ? request.sender.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                      : null,
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.sender.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wants to be your friend',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Accept button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _handleFriendRequestAccept(request),
                  ),
                ),

                const SizedBox(width: 12),

                // Reject button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _handleFriendRequestReject(request.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: request.receiver.avatar != null && request.receiver.avatar!.isNotEmpty
                  ? (request.receiver.avatar!.startsWith('http')
                  ? NetworkImage(request.receiver.avatar!)
                  : AssetImage('assets/images/${request.receiver.avatar}.png'))
                  : null,
              child: request.receiver.avatar == null || request.receiver.avatar!.isEmpty
                  ? Text(
                request.receiver.username.isNotEmpty
                    ? request.receiver.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.receiver.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Request sent',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cancel button
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: () => _showCancelRequestDialog(request),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelRequestDialog(FriendRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text('Cancel friend request to ${request.receiver.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async { // Make async
              Navigator.of(context).pop(); // Close dialog first
              final viewModel = Provider.of<FriendViewModel>(context, listen: false);

              // Call the ViewModel method
              await viewModel.cancelFriendRequest(request.id);

              // Check for errors and show appropriate message
              if (mounted) {
                if (viewModel.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling request: ${viewModel.errorMessage}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  // Optionally show success message (or rely on list updating)
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('Friend request cancelled'),
                  //     backgroundColor: Colors.orange,
                  //   ),
                  // );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendsTab(FriendViewModel viewModel) {
    // Trigger loading suggestions only if search results are empty and suggestions haven't been loaded/attempted
    if (viewModel.searchResults.isEmpty && viewModel.suggestedFriends == null && !viewModel.isLoadingSuggestions) {
      // Use a microtask to avoid triggering build during build phase
      Future.microtask(() => viewModel.loadSuggestedFriends());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for users by name or email',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.clearSearchResults();
                    // Optionally reload suggestions when search is cleared
                    viewModel.loadSuggestedFriends();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  viewModel.searchUsers(value);
                }
              },
              onChanged: (value) {
                // Clear results if search field is cleared
                if (value.isEmpty) {
                  viewModel.clearSearchResults();
                  // Optionally reload suggestions when search is cleared
                  viewModel.loadSuggestedFriends();
                } else {
                  // Optional: Live search - Trigger search on change (add debounce if needed)
                  // viewModel.searchUsers(value); 
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  FocusScope.of(context).unfocus(); // Hide keyboard
                  viewModel.searchUsers(_searchController.text);
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Results Area - Display Search Results OR Suggestions
          Expanded(
            child: _buildResultsArea(viewModel),
          ),
        ],
      ),
    );
  }

  // Helper widget to determine what to display in the results area
  Widget _buildResultsArea(FriendViewModel viewModel) {
    // Priority 1: Show search results if available
    if (viewModel.searchResults.isNotEmpty) {
      return _buildSearchResultsList(viewModel);
    }

    // Priority 2: Show loading indicator for suggestions
    if (viewModel.isLoadingSuggestions) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading suggestions..."),
          ],
        ),
      );
    }

    // Priority 3: Show suggestions if loaded and not empty
    if (viewModel.suggestedFriends != null && viewModel.suggestedFriends!.isNotEmpty) {
      return _buildSuggestedFriendsList(viewModel);
    }

    // Priority 4: Show error message if suggestions failed to load
    if (viewModel.errorMessage != null && viewModel.suggestedFriends != null && viewModel.suggestedFriends!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Failed to load suggestions.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => viewModel.loadSuggestedFriends(),
            ),
          ],
        ),
      );
    }

    // Priority 5: Show empty state (no search, no suggestions, no error)
    return _buildEmptySearchState();
  }

  // Widget to display when search is empty and no suggestions are available
  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GenieAvatar(
            state: AvatarState.idle,
            size: 100,
            message: "Find new friends!",
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for users or check out suggestions below.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching by username or email.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Renamed from _buildSuggestedFriends to avoid conflict 
  // This widget now specifically builds the LIST of suggestions
  Widget _buildSuggestedFriendsList(FriendViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Suggestions For You',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: viewModel.suggestedFriends!.length,
            itemBuilder: (context, index) {
              final user = viewModel.suggestedFriends![index];
              // Reuse the search result card styling
              return _buildUserCard(viewModel, user);
            },
          ),
        ),
      ],
    );
  }

  // Renamed from _buildSearchResultsList
  Widget _buildSearchResultsList(FriendViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Search Results (${viewModel.searchResults.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: viewModel.searchResults.length,
            itemBuilder: (context, index) {
              final user = viewModel.searchResults[index];
              return _buildUserCard(viewModel, user);
            },
          ),
        ),
      ],
    );
  }

  // Extracted common card builder for search results and suggestions
  Widget _buildUserCard(FriendViewModel viewModel, User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar (Existing Code)
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? (user.avatar!.startsWith('http')
                  ? NetworkImage(user.avatar!)
                  : AssetImage('assets/images/${user.avatar}.png'))
                  : null,
              child: user.avatar == null || user.avatar!.isEmpty
                  ? Text(
                user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // User info (Existing Code)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Add Friend Button (Existing Code)
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _handleSendFriendRequest(viewModel, user),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendFriendRequest(FriendViewModel viewModel, User user) async {
    // Show loading indicator in snackbar
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
            Text('Sending request to ${user.username}...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await viewModel.sendFriendRequest(user.id);

      // **** ADD THIS: Refresh requests AFTER sending ****
      await viewModel.loadFriendRequests();
      // ************************************************

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.username}'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to requests tab to see the sent request
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: ${viewModel.errorMessage ?? e}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveFriendDialog(User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: friend.avatar != null && friend.avatar!.isNotEmpty
                  ? (friend.avatar!.startsWith('http')
                  ? NetworkImage(friend.avatar!)
                  : AssetImage('assets/images/${friend.avatar}.png'))
                  : null,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: friend.avatar == null || friend.avatar!.isEmpty
                  ? Text(
                friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to remove ${friend.username} from your friends?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_remove, size: 18),
            label: const Text('Remove'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              final viewModel = Provider.of<FriendViewModel>(context, listen: false);
              viewModel.removeFriend(friend.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${friend.username} has been removed from your friends'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile({
    required User user,
    required Widget trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.avatar != null
            ? (user.avatar!.startsWith('http')
            ? NetworkImage(user.avatar!)
            : AssetImage('assets/images/${user.avatar}.png'))
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
            ? (user.avatar!.startsWith('http')
            ? NetworkImage(user.avatar!)
            : AssetImage('assets/images/${user.avatar}.png'))
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
                  ? (user.avatar!.startsWith('http')
                  ? NetworkImage(user.avatar!)
                  : AssetImage('assets/images/${user.avatar}.png'))
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