import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_model.dart';
import '../../data/repositories/friend_repository.dart';

class FriendViewModel extends ChangeNotifier {
  final FriendRepository _friendRepository;
  
  List<User> _friends = [];
  FriendRequests? _friendRequests;
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<User> get friends => _friends;
  FriendRequests? get friendRequests => _friendRequests;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  FriendViewModel({required FriendRepository friendRepository})
      : _friendRepository = friendRepository;
  
  // Load friends
  Future<void> loadFriends() async {
    try {
      _setLoading(true);
      _clearError();
      
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
        Future.delayed(Duration(seconds: 2), () {
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
    try {
      print('Quietly refreshing friends data...');
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
  
  // Load friend requests
  Future<void> loadFriendRequests() async {
    try {
      _setLoading(true);
      _clearError();
      
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
      await _friendRepository.acceptFriendRequest(requestId);
      
      // Then refresh friends list - make sure this happens after the acceptance
      await loadFriends();
      
      // Finally refresh the requests to remove the accepted request
      await loadFriendRequests();
      
      // Log confirmation for debugging
      print('Friend request accepted, refreshed lists. Friends count: ${_friends.length}');
    } catch (e) {
      _setError('Failed to accept friend request: $e');
      _setLoading(false);
    }
  }
  
  // Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _friendRepository.rejectFriendRequest(requestId);
      
      // Refresh friend requests after rejecting
      await loadFriendRequests();
    } catch (e) {
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