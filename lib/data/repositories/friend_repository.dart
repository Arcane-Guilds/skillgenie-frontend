import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';


class FriendRepository {
  final Logger _logger = Logger();
  final http.Client _client;

  FriendRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleApiError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorBody = jsonDecode(response.body);
      final message = errorBody['message'] ?? 'An error occurred';
      _logger.e('API Error: $message');
      throw Exception(message);
    }
  }

  Future<List<User>> getFriends() async {
    try {
      _logger.i('Fetching friends');
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/friends'),
        headers: headers,
      );

      _handleApiError(response);

      // Log the raw response for debugging
      _logger.d('Friends API response: ${response.body}');
      
      // Handle empty response
      if (response.body.isEmpty || response.body == '[]') {
        _logger.i('Empty friends list from API');
        return [];
      }
      
      final dynamic decodedJson = jsonDecode(response.body);
      
      // Case 1: Response is an array of objects
      if (decodedJson is List) {
        List<User> friends = [];
        
        for (var item in decodedJson) {
          try {
            // Case 1a: Item is a string (just an ID)
            if (item is String) {
              _logger.d('Friend item is a string ID: $item');
              // When we just have an ID, we need to fetch the user details separately
              // For now, create a minimal user with just ID
              friends.add(User(
                id: item,
                username: 'Friend', 
                email: 'Loading...'
              ));
            } 
            // Case 1b: Item is a User object
            else if (item is Map<String, dynamic>) {
              _logger.d('Friend item is a user object');
              final user = User.fromJson(item);
              friends.add(user);
            }
          } catch (e) {
            _logger.e('Error parsing friend data: $e. Raw data: $item');
          }
        }
        
        _logger.i('Parsed ${friends.length} friends from API');
        return friends;
      } 
      // Case 2: Response is an object with a data field
      else if (decodedJson is Map && decodedJson.containsKey('data')) {
        final List<dynamic> data = decodedJson['data'];
        _logger.d('Friend data found in "data" field, ${data.length} items');
        
        return data.map((item) => User.fromJson(item)).toList();
      }
      
      // Fall through case - no valid data found
      _logger.w('Unexpected response format: ${response.body}');
      return [];
    } catch (e) {
      _logger.e('Error fetching friends: $e');
      rethrow;
    }
  }

  Future<FriendRequests> getFriendRequests() async {
    try {
      _logger.i('Fetching friend requests');
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/friends/requests'),
        headers: headers,
      );

      _handleApiError(response);

      final data = jsonDecode(response.body);
      return FriendRequests.fromJson(data);
    } catch (e) {
      _logger.e('Error fetching friend requests: $e');
      rethrow;
    }
  }

  Future<FriendRequest> sendFriendRequest(String receiverId) async {
    try {
      _logger.i('Sending friend request to $receiverId');
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/friends/requests/$receiverId'),
        headers: headers,
      );

      _handleApiError(response);

      final data = jsonDecode(response.body);
      return FriendRequest.fromJson(data);
    } catch (e) {
      _logger.e('Error sending friend request: $e');
      rethrow;
    }
  }

  Future<FriendRequest> acceptFriendRequest(String requestId) async {
    try {
      _logger.i('Accepting friend request: $requestId');
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/friends/requests/$requestId/accept'),
        headers: headers,
      );

      _handleApiError(response);

      final data = jsonDecode(response.body);
      return FriendRequest.fromJson(data);
    } catch (e) {
      _logger.e('Error accepting friend request: $e');
      rethrow;
    }
  }

  Future<FriendRequest> rejectFriendRequest(String requestId) async {
    try {
      _logger.i('Rejecting friend request: $requestId');
      final headers = await _getAuthHeaders();
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/friends/requests/$requestId/reject'),
        headers: headers,
      );

      _handleApiError(response);

      final data = jsonDecode(response.body);
      return FriendRequest.fromJson(data);
    } catch (e) {
      _logger.e('Error rejecting friend request: $e');
      rethrow;
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      _logger.i('Removing friend: $friendId');
      final headers = await _getAuthHeaders();
      final response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}/friends/$friendId'),
        headers: headers,
      );

      _handleApiError(response);
      _logger.i('Friend removed successfully');
    } catch (e) {
      _logger.e('Error removing friend: $e');
      rethrow;
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      _logger.i('Searching users with query: $query');
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/user/search?q=$query'),
        headers: headers,
      );

      _handleApiError(response);

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error searching users: $e');
      rethrow;
    }
  }
}
