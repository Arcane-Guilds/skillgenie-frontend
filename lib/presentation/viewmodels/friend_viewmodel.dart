import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_model.dart';
import '../../data/repositories/friend_repository.dart';

class FriendViewModel extends ChangeNotifier {
  final FriendRepository _friendRepository;
  
  List<User> _friends = [];
  FriendRequests? _friendRequests;
  List<User> _searchResults = [];
  List<User>? _suggestedFriends;
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  String? _errorMessage;
  
  // Throttling variables
  DateTime _lastFriendsApiCall = DateTime(1970);
  DateTime _lastRequestsApiCall = DateTime(1970);
  DateTime _lastSuggestionsApiCall = DateTime(1970);
  bool _friendsRefreshQueued = false;
  
  // Getters
  List<User> get friends => _friends;
  FriendRequests? get friendRequests => _friendRequests;
  List<User> get searchResults => _searchResults;
  List<User>? get suggestedFriends => _suggestedFriends;
  bool get isLoading => _isLoading;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  FriendViewModel({required FriendRepository friendRepository})
      : _friendRepository = friendRepository;
  
  // Check if we should throttle an API call
  bool _shouldThrottle(DateTime lastCall, {int minIntervalSeconds = 5}) {
    final now = DateTime.now();
    return now.difference(lastCall).inSeconds < minIntervalSeconds;
  }
  
  // Load friends with throttling
  Future<void> loadFriends() async {
    // Skip if already loading or if we called the API too recently
    if (_isLoading) {
      print('Skipping loadFriends - already loading');
      return;
    }
    
    if (_shouldThrottle(_lastFriendsApiCall)) {
      print('Throttling loadFriends - called too recently');
      
      // If we need to refresh and aren't already queued, schedule a refresh
      if (!_friendsRefreshQueued) {
        _friendsRefreshQueued = true;
        Future.delayed(const Duration(seconds: 2), () {
          _friendsRefreshQueued = false;
          loadFriends();
        });
      }
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      _lastFriendsApiCall = DateTime.now();
      
      print('Loading friends...');
      _friends = await _friendRepository.getFriends();
      print('Friends loaded: ${_friends.length} friends');
      
      // Check if we need to load full user details for any "shell" users
      // (users with just an ID)
      bool needsRefresh = false;
      for (final friend in _friends) {
        if (friend.username == 'Friend' && friend.email == 'Loading...') {
          needsRefresh = true;
          // We could fetch individual user details here if API supported it
          // For now we'll just mark that we need a proper refresh
        }
      }
      
      // If any users were just shells with IDs, we'll make one more final request
      // to get the proper data after a short delay
      if (needsRefresh) {
        print('Some friends had only IDs, will refresh friend data shortly');
        // Small delay to prevent bombarding the server
        Future.delayed(const Duration(seconds: 2), () {
          if (!_isLoading) {
            // Load friends from scratch but don't show loading spinner again
            _refreshFriendsQuietly();
          }
        });
      }
      
      // If friends list is empty, log more details
      if (_friends.isEmpty) {
        print('No friends found. This could be because:');
        print('1. You have no friends added yet');
        print('2. There might be an issue with the API connection');
        print('3. There might be a mismatch in the friends data structure');
      } else {
        // Log the first few friends for debugging
        print('First few friends:');
        for (int i = 0; i < _friends.length && i < 3; i++) {
          print('Friend ${i+1}: ${_friends[i].username} (${_friends[i].id})');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading friends: $e');
      _setError('Failed to load friends: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Refresh friends quietly without showing loading state
  Future<void> _refreshFriendsQuietly() async {
    // Skip if we called the API too recently
    if (_shouldThrottle(_lastFriendsApiCall, minIntervalSeconds: 2)) {
      print('Throttling quiet refresh - called too recently');
      return;
    }
    
    try {
      print('Quietly refreshing friends data...');
      _lastFriendsApiCall = DateTime.now();
      final updatedFriends = await _friendRepository.getFriends();
      
      if (updatedFriends.isNotEmpty) {
        _friends = updatedFriends;
        print('Successfully refreshed ${_friends.length} friends');
        notifyListeners();
      }
    } catch (e) {
      print('Error during quiet refresh: $e');
      // Don't show error to user for background refresh
    }
  }
  
  // Load friend requests with throttling
  Future<void> loadFriendRequests() async {
    // Skip if already loading or if we called the API too recently
    if (_isLoading) {
      print('Skipping loadFriendRequests - already loading');
      return;
    }
    
    if (_shouldThrottle(_lastRequestsApiCall)) {
      print('Throttling loadFriendRequests - called too recently');
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      _lastRequestsApiCall = DateTime.now();
      
      _friendRequests = await _friendRepository.getFriendRequests();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load friend requests: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Search users
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      _searchResults = await _friendRepository.searchUsers(query);
      notifyListeners();
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Send friend request
  Future<void> sendFriendRequest(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.sendFriendRequest(userId);
      
      // Refresh friend requests after sending
      await loadFriendRequests();
    } catch (e) {
      _setError('Failed to send friend request: $e');
      _setLoading(false);
    }
  }
  
  // Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // First accept the request
      final acceptedRequest = await _friendRepository.acceptFriendRequest(requestId);
      
      // Get the sender's ID and info to create a chat with them
      final friendId = acceptedRequest.sender.id;
      final newFriend = acceptedRequest.sender;
      
      // Update local friends list immediately
      if (!_friends.any((friend) => friend.id == newFriend.id)) {
        _friends.add(newFriend);
        notifyListeners();
      }
      
      // Update local friend requests list to remove this request
      if (_friendRequests != null) {
        _friendRequests!.received.removeWhere((request) => request.id == requestId);
        notifyListeners();
      }
      
      // Create a chat with the new friend using the standard POST endpoint
      try {
        print('Creating chat with new friend: $friendId');
        final chatResult = await _friendRepository.createChatWithFriend(friendId);
        print('Chat created: ${chatResult['id'] ?? 'Unknown ID'}');
      } catch (chatError) {
        print('Warning: Could not create chat with friend: $chatError');
        // Don't fail the whole operation if chat creation fails
      }
      
      // Then refresh friends list in background - this should be fast since we already added the friend locally
      _lastFriendsApiCall = DateTime(1970); // Reset throttling to force refresh
      loadFriends().then((_) {
        print('Background friends refresh completed');
      });
      
      // Finally refresh the requests to ensure we're in sync with the server
      _lastRequestsApiCall = DateTime(1970); // Reset throttling to force refresh
      loadFriendRequests().then((_) {
        print('Background requests refresh completed');
      });
      
      // Log confirmation for debugging
      print('Friend request accepted, lists updated. Friends count: ${_friends.length}');
      
      _setLoading(false);
    } catch (e) {
      print('Error during accept friend request: $e');
      _setError('Failed to accept friend request: $e');
      _setLoading(false);
    }
  }
  
  // Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // First reject the request on the server
      await _friendRepository.rejectFriendRequest(requestId);
      
      // Update local friend requests list to remove this request
      if (_friendRequests != null) {
        _friendRequests!.received.removeWhere((request) => request.id == requestId);
        notifyListeners();
      }
      
      // Refresh friend requests in the background to ensure we're in sync with the server
      _lastRequestsApiCall = DateTime(1970); // Reset throttling to force refresh
      loadFriendRequests().then((_) {
        print('Background requests refresh completed after rejection');
      });
      
      _setLoading(false);
    } catch (e) {
      print('Error rejecting friend request: $e');
      _setError('Failed to reject friend request: $e');
      _setLoading(false);
    }
  }
  
  // Remove friend
  Future<void> removeFriend(String friendId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.removeFriend(friendId);
      
      // Remove from local list
      _friends.removeWhere((friend) => friend.id == friendId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove friend: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load suggested friends with throttling and error handling
  Future<void> loadSuggestedFriends() async {
    // Skip if already loading suggestions or if called too recently
    if (_isLoadingSuggestions || _shouldThrottle(_lastSuggestionsApiCall, minIntervalSeconds: 10)) {
      print('Skipping/Throttling loadSuggestedFriends.');
      return;
    }

    try {
      _isLoadingSuggestions = true;
      _suggestedFriends = null; // Clear previous suggestions
      _clearError(); // Clear previous errors before loading
      notifyListeners();

      _lastSuggestionsApiCall = DateTime.now();
      print('Loading suggested friends...');
      
      final suggestions = await _friendRepository.getSuggestedFriends();
      _suggestedFriends = suggestions;
      
      print('Suggested friends loaded: ${_suggestedFriends?.length ?? 0} suggestions');
    } catch (e) {
      print('Error loading suggested friends: $e');
      _setError('Failed to load suggestions: $e');
      _suggestedFriends = []; // Set to empty list on error to avoid null issues
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
} 