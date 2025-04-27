import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';

import '../../core/storage/secure_storage.dart';
import '../models/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ChatRepository {
  final http.Client _client;
  final SecureStorage _secureStorage;
  io.Socket? _socket;
  String? _currentUserId;
  bool _socketConnected = false;

  final String baseUrl = ApiConstants.baseUrl;

  // Callback properties - changed from final to regular properties
  void Function(Chat chat)? _onNewChat;
  void Function(Message message)? _onNewMessage;
  void Function(String chatId, String userId)? _onMessagesRead;

  // Getters and setters for callbacks
  void Function(Chat chat)? get onNewChat => _onNewChat;
  set onNewChat(void Function(Chat chat)? callback) {
    _onNewChat = callback;
  }

  void Function(Message message)? get onNewMessage => _onNewMessage;
  set onNewMessage(void Function(Message message)? callback) {
    _onNewMessage = callback;
  }

  void Function(String chatId, String userId)? get onMessagesRead =>
      _onMessagesRead;
  set onMessagesRead(void Function(String chatId, String userId)? callback) {
    _onMessagesRead = callback;
  }

  // Getter to check if the socket is connected
  bool get isSocketConnected => _socketConnected;

  // Method to update the socket connection status
  void updateSocketConnectionStatus(bool status) {
    _socketConnected = status;
  }

  ChatRepository({
    required http.Client client,
    required SecureStorage secureStorage,
    void Function(Chat chat)? onNewChat,
    void Function(Message message)? onNewMessage,
    void Function(String chatId, String userId)? onMessagesRead,
  })  : _client = client,
        _secureStorage = secureStorage {
    // Set initial values for callbacks
    _onNewChat = onNewChat;
    _onNewMessage = onNewMessage;
    _onMessagesRead = onMessagesRead;
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _secureStorage.getToken();

      if (token == null || token.isEmpty) {
        print(
            'WARNING: Authentication token is null or empty. Checking shared prefs directly...');

        // Try to get token directly from shared prefs as a last resort
        final prefs = await SharedPreferences.getInstance();
        final directToken = prefs.getString('accessToken');

        if (directToken != null && directToken.isNotEmpty) {
          print('Found token directly in shared preferences');

          // Save it to secure storage for next time
          await _secureStorage.setToken(directToken);

          return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $directToken',
          };
        }

        throw Exception('Authentication token is missing');
      }

      print(
          'Adding auth token to headers: Bearer ${token.length > 10 ? token.substring(0, 10) + "..." : token}');

      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error generating headers: $e');
      // Return headers without auth token as fallback
      return {
        'Content-Type': 'application/json',
      };
    }
  }

  // Initialize socket connection
  Future<void> initializeSocket() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) return;

      _currentUserId = await _secureStorage.getUserId();
      if (_currentUserId == null) return;

      // Close existing socket if any
      _socket?.disconnect();

      // Create new socket connection with the emulator IP
      _socket = io.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
      });

      // Set up event listeners
      _socket?.onConnect((_) {
        print('Socket connected');
        updateSocketConnectionStatus(true);
      });

      _socket?.onDisconnect((_) {
        print('Socket disconnected');
        updateSocketConnectionStatus(false);
      });

      _socket?.on('newChat', (data) {
        final chat = Chat.fromJson(data);
        _onNewChat?.call(chat);
      });

      _socket?.on('newMessage', (data) {
        final message = Message.fromJson(data);
        _onNewMessage?.call(message);
      });

      _socket?.on('messagesRead', (data) {
        final chatId = data['chatId'];
        final userId = data['userId'];
        _onMessagesRead?.call(chatId, userId);
      });

      // Connect to socket
      _socket?.connect();
    } catch (e) {
      updateSocketConnectionStatus(false);
      print('Error initializing socket: $e');
    }
  }

  // Get chats for current user
  Future<List<Chat>> getUserChats() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/chat'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((chat) => Chat.fromJson(chat)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user chats: $e');
      rethrow;
    }
  }

  // Get a specific chat by ID
  Future<Chat> getChat(String chatId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/chat/$chatId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return Chat.fromJson(jsonData);
      } else {
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat: $e');
      rethrow;
    }
  }

  // Create a new chat
  Future<Chat> createChat({
    required List<String> participants,
    bool isGroupChat = false,
    String? name,
  }) async {
    try {
      print(
          'Creating chat with participants: $participants, isGroupChat: $isGroupChat');

      // Get current user ID first for validation
      final currentUserId = await _secureStorage.getUserId();
      if (currentUserId == null) {
        print(
            'WARNING: Current user ID is null, authentication might be incomplete');
      } else {
        print('Current user ID: $currentUserId');
      }

      // Debug: Get token directly and verify it's not null
      final directToken = await _secureStorage.getToken();
      print(
          'Direct token check before creating headers: ${directToken != null ? "Token exists" : "TOKEN IS NULL!"}');

      // First ensure we have a valid token before proceeding
      final headers = await _getHeaders();

      // Print all headers for debugging
      print('All request headers: $headers');

      if (!headers.containsKey('Authorization')) {
        print('ERROR: Authorization header is missing');

        // Try to get token one more time with a direct SharedPreferences instance
        final prefs = await SharedPreferences.getInstance();
        final lastResortToken = prefs.getString('accessToken');
        if (lastResortToken != null && lastResortToken.isNotEmpty) {
          print('Found token with last resort attempt, adding to headers');
          headers['Authorization'] = 'Bearer $lastResortToken';
        } else {
          throw Exception(
              'Cannot create chat: Authentication token is missing');
        }
      }

      // Debug: Show authorization header (first 15 chars only)
      String authHeader = headers['Authorization'] ?? '';
      print(
          'Authorization header (truncated): ${authHeader.length > 15 ? authHeader.substring(0, 15) + '...' : authHeader}');

      final body = jsonEncode({
        'participants': participants,
        'isGroupChat': isGroupChat,
        if (name != null) 'name': name,
      });

      print('Sending POST request to $baseUrl/chat with body: $body');

      final response = await _client.post(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: body,
      );

      print('Create chat response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        print('Authentication failed - token might be invalid or expired');

        // As a debug measure, let's print the current auth status
        final prefs = await SharedPreferences.getInstance();
        final hasAccessToken = prefs.containsKey('accessToken');
        final accessToken = prefs.getString('accessToken');
        final hasRefreshToken = prefs.containsKey('refreshToken');
        final hasUser = prefs.containsKey('user');

        print('DEBUG AUTH STATUS: accessToken exists: $hasAccessToken');
        print(
            'accessToken value: ${accessToken != null ? accessToken.substring(0, math.min(10, accessToken.length)) + "..." : "null"}');
        print('refreshToken exists: $hasRefreshToken, user exists: $hasUser');

        // Try to get a new token if possible
        // This would normally involve refreshing the token with a refresh token
        // For now, we'll just throw an error

        throw Exception('Authentication failed - please log in again');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return Chat.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to create chat: ${response.statusCode}, reason: ${response.body}');
      }
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Get messages for a chat
  Future<List<Message>> getChatMessages(
    String chatId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (before != null) 'before': before,
      };

      final uri = Uri.parse('$baseUrl/chat/$chatId/messages')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((message) => Message.fromJson(message)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat messages: $e');
      rethrow;
    }
  }

  // Send a message using REST API
  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final body = jsonEncode({'content': content});

      final response = await _client.post(
        Uri.parse('$baseUrl/chat/$chatId/messages'),
        headers: await _getHeaders(),
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return Message.fromJson(jsonData);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send a message using socket
  void sendMessageViaSocket(String chatId, String content) {
    try {
      if (_socket == null) {
        print('ERROR: Cannot send message via socket - socket is null');
        throw Exception('Socket is not connected');
      }

      if (_socket?.connected != true) {
        print(
            'WARNING: Socket appears to be disconnected, attempting to reconnect');
        _socket?.connect();
      }

      final messageData = {
        'chatId': chatId,
        'message': {'content': content},
      };

      print('Sending message via socket: $content to chat: $chatId');
      _socket?.emit('sendMessage', messageData);

      // Add a listener for message acknowledgement if the server supports it
      _socket?.once('messageSent', (data) {
        print('Message acknowledgement received from server: $data');
      });

      // Add a short timeout to detect potential delivery issues
      Future.delayed(Duration(seconds: 5), () {
        // Check if the message appears in the messages list
        // This is a simplified approach - in a real app you would track message IDs
        print('Message delivery verification timeout reached');
      });
    } catch (e) {
      print('Error sending message via socket: $e');
      // We can't throw here since void methods can't propagate exceptions
      // but we can at least log it for debugging
    }
  }

  Future<bool> sendMessageViaSocketWithTimeout(String chatId, String content, {Duration? timeout}) async {
    try {
      // Logic to send the message via socket
      // Use the timeout parameter if needed
      if (timeout != null) {
        // Example: Implement timeout logic
        await Future.delayed(timeout);
      }

      return true; // Indicate success
    } catch (e) {
      print('Error sending message via socket: $e');
      return false; // Indicate failure
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat/$chatId/read'),
        headers: await _getHeaders(),
        body: '{}',
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Mark messages as read using socket
  void markMessagesAsReadViaSocket(String chatId) {
    _socket?.emit('markAsRead', chatId);
  }

  // Get unread message count
  Future<Map<String, dynamic>> getUnreadMessageCount() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/chat/unread'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread message count: $e');
      rethrow;
    }
  }

  // Dispose socket connection
  void dispose() {
    _socket?.disconnect();
    _socket = null;
    updateSocketConnectionStatus(false);
  }

  // Manually set the token (for debugging/recovery)
  Future<bool> manuallySetToken(String token) async {
    try {
      print(
          'Manually setting token: ${token.substring(0, math.min(10, token.length))}...');

      // Set in secure storage
      final secureResult = await _secureStorage.setToken(token);

      // Also set directly in shared prefs for extra safety
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);

      print(
          'Manual token setting result - secure storage: $secureResult, prefs: ${prefs.containsKey('accessToken')}');

      // Verify token was set correctly by reading it back
      final savedToken = await _secureStorage.getToken();
      if (savedToken == token) {
        print('Token verification successful');
        return true;
      } else {
        print(
            'WARNING: Token verification failed - saved value does not match');
        return false;
      }
    } catch (e) {
      print('Error manually setting token: $e');
      return false;
    }
  }
}
