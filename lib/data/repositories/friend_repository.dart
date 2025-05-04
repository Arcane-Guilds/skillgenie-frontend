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

  FriendRepository({required http.Client client}) : _client = client;

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
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'An error occurred';
        _logger.e('API Error: $message');
        throw Exception(message);
      } catch (e) {
        _logger.e('Failed to parse error response: ${response.body}');
        throw Exception('An error occurred: ${response.statusCode}');
      }
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

      // Case 1: Response is an array of objects or strings
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
      
      // Validate query length before calling API
      if (query.isEmpty || query.length < 2) {
        _logger.w('Search query too short, returning empty list.');
        return [];
      }
      
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

  // Create a chat with a friend after accepting friend request
  Future<Map<String, dynamic>> createChatWithFriend(String friendId) async {
    try {
      _logger.i('Creating chat with friend: $friendId');

      // First, check if a chat already exists with this friend
      final existingChat = await _checkExistingChatWithFriend(friendId);
      if (existingChat != null) {
        _logger.i('Chat already exists with friend: $friendId');
        return existingChat;
      }

      final headers = await _getAuthHeaders();

      // Use the standard POST endpoint for chat creation
      final requestBody = jsonEncode({
        'participants': [friendId],
        'isGroupChat': false,
      });

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/chat'),
        headers: headers,
        body: requestBody,
      );

      _handleApiError(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _logger.i('Chat created successfully with friend: $friendId');
        return jsonDecode(response.body);
      } else {
        _logger.w('Unexpected status code when creating chat: ${response
            .statusCode}');
        throw Exception('Failed to create chat with friend');
      }
    } catch (e) {
      _logger.e('Error creating chat with friend: $e');
      rethrow;
    }
  }

  // Check if a chat already exists with a specific friend
  Future<Map<String, dynamic>?> _checkExistingChatWithFriend(
      String friendId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/chat'),
        headers: headers,
      );

      _handleApiError(response);

      if (response.statusCode == 200) {
        final List<dynamic> chats = jsonDecode(response.body);

        // Look for a direct chat with the friend
        for (var chat in chats) {
          // Check if it's a direct (non-group) chat
          if (chat['isGroupChat'] == false) {
            // Check if the friend is a participant
            final List<dynamic> participants = chat['participants'];

            // Loop through participants to find the friend
            bool friendFound = false;
            for (var participant in participants) {
              String participantId = '';

              // Handle both string IDs and full user objects
              if (participant is String) {
                participantId = participant;
              } else if (participant is Map && participant.containsKey('id')) {
                participantId = participant['id'];
              } else if (participant is Map && participant.containsKey('_id')) {
                participantId = participant['_id'];
              }

              if (participantId == friendId) {
                friendFound = true;
                break;
              }
            }

            if (friendFound) {
              _logger.i('Found existing chat with friend: $friendId');
              return chat;
            }
          }
        }
      }

      return null;
    } catch (e) {
      _logger.e('Error checking existing chats: $e');
      return null; // Return null if there's an error, to allow chat creation
    }
  }

  // Fetch suggested friends from the backend
  Future<List<User>> getSuggestedFriends() async {
    try {
      _logger.i('Fetching suggested friends from API');
      final headers = await _getAuthHeaders();
      
      // Call the suggestions endpoint
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/friends/suggestions'),
        headers: headers,
      );

      _handleApiError(response);

      final List<dynamic> data = jsonDecode(response.body);
      _logger.i('Successfully fetched ${data.length} suggested friends');
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error fetching suggested friends: $e');
      rethrow; // Rethrow the error to be handled by the ViewModel
    }
  }

}
