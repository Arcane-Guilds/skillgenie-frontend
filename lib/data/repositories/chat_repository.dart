import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';

import '../../core/storage/secure_storage.dart';
import '../models/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';

class ChatRepository {
  final http.Client _client;
  final SecureStorage _secureStorage;
  io.Socket? _socket;
  String? _currentUserId;
  bool _socketConnected = false;
  bool _socketInitialized = false; // Track if socket has been initialized
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;

  final String baseUrl = ApiConstants.baseUrl;

  // Callback properties - changed from final to regular properties
  dynamic _onNewChat;
  dynamic _onNewMessage;
  dynamic _onMessagesRead;
  dynamic _onConnectionStatusChanged;
  dynamic _onPong; // Add callback for pong responses

  // Getters for callback properties
  set onNewChat(dynamic callback) => _onNewChat = callback;
  set onNewMessage(dynamic callback) => _onNewMessage = callback;
  set onMessagesRead(dynamic callback) => _onMessagesRead = callback;
  set onConnectionStatusChanged(dynamic callback) => _onConnectionStatusChanged = callback;
  set onPong(dynamic callback) => _onPong = callback; // Getter for pong callback
  
  // Add getter for socket initialized state
  bool get isSocketInitialized => _socketInitialized;

  // Getter for connection status
  bool get isSocketConnected => _socketConnected;

  // Method to update the socket connection status AND notify listener
  void updateSocketConnectionStatus(bool status) {
    if (_socketConnected != status) {
       _socketConnected = status;
       print('ChatRepository: Socket connection status changed to: $status');
       if (_onConnectionStatusChanged != null) {
         try {
            _onConnectionStatusChanged(status);
         } catch (e) {
            print('Error calling onConnectionStatusChanged callback: $e');
         }
       }
    }
  }

  ChatRepository({
    required http.Client client,
    required SecureStorage secureStorage,
    dynamic onNewChat,
    dynamic onNewMessage,
    dynamic onMessagesRead,
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
        print('WARNING: Authentication token is null or empty. Checking shared prefs directly...');

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

      print('Adding auth token to headers: Bearer ${token.length > 10 ? "${token.substring(0, 10)}..." : token}');

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

  // Send a ping to test the connection
  void sendPing() {
    try {
      if (_socket == null) {
        print('Cannot send ping - socket is null');
        return;
      }
      
      if (!_socketConnected) {
        print('Cannot send ping - socket not connected');
        return;
      }
      
      print('Sending ping to socket server');
      _socket!.emit('ping');
    } catch (e) {
      print('Error sending ping: $e');
    }
  }

  // Initialize socket connection
  Future<void> initializeSocket() async {
    try {
      if (_socket?.connected == true) {
        print('Socket already connected, skipping initialization');
        updateSocketConnectionStatus(true);
        _socketInitialized = true;
        return;
      }
      
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        print('ERROR: Cannot initialize socket - token is null or empty');
        throw Exception('Authentication token is required for socket connection');
      }

      _currentUserId = await _secureStorage.getUserId();
      if (_currentUserId == null) {
        print('ERROR: Cannot initialize socket - current user ID is null');
        throw Exception('User ID is required for socket connection');
      }
      
      // Create the full socket URL with namespace - using the correct format
      // Socket.IO client connects to the namespace by appending it to the URL path
      final namespace = 'chat';
      final socketUrl = '$baseUrl/$namespace';  // Namespace is part of the URL
      print('Initializing socket to $socketUrl');
      print('Auth: token=${token.substring(0, math.min(10, token.length))}... userId=$_currentUserId');

      // Close existing socket if any
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;

      // Create new socket connection with namespace included in URL
      _socket = io.io(
        socketUrl, 
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .setAuth({'token': token})
          // Namespace is already in the URL, don't set it here
          .build(),
      );

      // Set up event listeners
      _socket?.onConnect((_) {
        print('Socket connected successfully to $socketUrl');
        _reconnectAttempts = 0; // Reset reconnect attempts
        // _socketInitialized = true; // ViewModel will manage this based on callback
        updateSocketConnectionStatus(true);
      });

      _socket?.onConnectError((error) {
        print('Socket connection error: $error');
        updateSocketConnectionStatus(false);
      });

      _socket?.onError((error) {
        print('Socket error: $error');
        updateSocketConnectionStatus(false);
      });

      _socket?.onDisconnect((reason) {
        print('Socket disconnected: $reason');
        updateSocketConnectionStatus(false);
        // Optionally trigger reconnect attempt here if needed, respecting limits
        // if (_reconnectAttempts < _maxReconnectAttempts) { ... }
      });

      // Specific event listeners
      _socket?.on('connectionEstablished', (data) {
        print('Received connectionEstablished event: $data');
      });

      _socket?.on('newChat', (data) {
        print('Received newChat event: $data');
        if (_onNewChat != null) {
          _onNewChat(data);
        }
      });

      _socket?.on('newMessage', (data) {
        print('Received newMessage event: $data');
        if (_onNewMessage != null) {
          _onNewMessage(data);
        }
      });

      _socket?.on('messagesRead', (data) {
        print('Received messagesRead event: $data');
        if (_onMessagesRead != null) {
          final chatId = data['chatId'];
          final userId = data['userId'];
          _onMessagesRead(chatId, userId);
        }
      });
      
      // Add listener for pong responses
      _socket?.on('pong', (data) {
        print('Received pong response: $data');
        if (_onPong != null) {
          _onPong(data);
        }
      });

      // Add listeners for error events
      _socket?.on('authError', (data) {
        print('Authentication error: $data');
        updateSocketConnectionStatus(false);
      });
      
      _socket?.on('error', (data) {
        print('Socket error event: $data');
        updateSocketConnectionStatus(false);
      });

      // Connect to socket
      print('Attempting to connect socket...');
      _socket?.connect();

      // Add extra check to verify connection
      Future.delayed(const Duration(seconds: 3), () {
        if (_socket?.connected != true) {
          print('Socket still not connected after 3 seconds, connection may have failed');
          print('Connection state: ${_socket?.connected}');
          _socketInitialized = _socket?.connected == true;
          updateSocketConnectionStatus(false);
        } else {
          print('Socket connection verified after 3 seconds');
          _socketInitialized = true;
          updateSocketConnectionStatus(true);
        }
      });
      
    } catch (e) {
      print('Error initializing socket: $e');
      _socketInitialized = false;
      updateSocketConnectionStatus(false);
      rethrow;
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
          'Authorization header (truncated): ${authHeader.length > 15 ? '${authHeader.substring(0, 15)}...' : authHeader}');

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
            'accessToken value: ${accessToken != null ? "${accessToken.substring(0, math.min(10, accessToken.length))}..." : "null"}');
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
  void sendMessageViaSocket(String chatId, String content, {String? tempId}) {
    try {
      if (_socket == null) {
        print('ERROR: Cannot send message via socket - socket is null');
        throw Exception('Socket is not connected');
      }

      if (_socket?.connected != true) {
        print('WARNING: Socket appears to be disconnected, attempting to reconnect');
        _socket?.connect();
        throw Exception('Socket is not connected');
      }

      final messageData = {
        'chatId': chatId,
        'message': {'content': content},
        if (tempId != null) 'tempId': tempId,
      };

      print('Sending message via socket: $content to chat: $chatId');
      _socket?.emit('sendMessage', messageData);

      // Add a listener for message acknowledgement if the server supports it
      _socket?.once('messageSent', (data) {
        print('Message acknowledgement received from server: $data');
      });
    } catch (e) {
      print('Error sending message via socket: $e');
      throw e; // Rethrow to let the ViewModel handle it
    }
  }

  Future<bool> sendMessageViaSocketWithTimeout(String chatId, String content, {Duration? timeout, String? tempId}) async {
    try {
      // Check prerequisites
      if (chatId.isEmpty) {
        print('Cannot send message: chatId is empty');
        return false;
      }
      
      if (content.isEmpty) {
        print('Cannot send message: content is empty');
        return false;
      }
      
      if (_socket == null) {
        print('Cannot send message: socket is null');
        return false;
      }
      
      if (_socket?.connected != true) {
        print('Socket not connected for timed message send');
        
        // Try to reconnect before giving up
        try {
          print('Attempting to reconnect socket before sending message');
          _socket?.connect();
          // Wait briefly to see if connection succeeds
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (_socket?.connected != true) {
            print('Reconnect failed, cannot send message via socket');
            return false;
          }
        } catch (e) {
          print('Error reconnecting socket: $e');
          return false;
        }
      }

      // Prepare message data
      final messageData = {
        'chatId': chatId,
        'message': {'content': content},
        if (tempId != null) 'tempId': tempId,
      };

      print('Sending message via socket with timeout: "$content" to chat: $chatId');
      print('Socket connected status: ${_socket?.connected}');
      
      // Emit the message to the server
      _socket?.emit('sendMessage', messageData);

      // If timeout provided, wait for acknowledgement or timeout
      if (timeout != null) {
        final completer = Completer<bool>();
        
        // Setup one-time listener for acknowledgement
        _socket?.once('messageSent', (data) {
          if (!completer.isCompleted) {
            print('Message acknowledgement received from server: $data');
            completer.complete(true);
          }
        });
        
        // Also listen for error response
        _socket?.once('sendMessageError', (data) {
          if (!completer.isCompleted) {
            print('Error response from server: $data');
            completer.complete(false);
          }
        });

        // Setup timeout
        Future.delayed(timeout, () {
          if (!completer.isCompleted) {
            print('Message send timed out after ${timeout.inSeconds} seconds');
            completer.complete(false);
          }
        });

        return await completer.future;
      }

      return true; // If no timeout specified, assume success
    } catch (e) {
      print('Error sending message via socket with timeout: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat/$chatId/read'),
        headers: await _getHeaders(),
        body: '{}', // Sending an empty JSON object as body
      );

      // Accept 200 OK or 201 Created as success
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to mark messages as read: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to mark messages as read: ${response.statusCode}');
      } else {
        print('Successfully marked messages as read for chat $chatId (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Mark messages as read using socket
  void markMessagesAsReadViaSocket(String chatId) {
    try {
      if (_socket == null || _socket?.connected != true) {
        print('WARNING: Socket not connected when marking messages as read');
        return;
      }
      
      print('Marking messages as read via socket for chat: $chatId');
      _socket?.emit('markAsRead', chatId);
    } catch (e) {
      print('Error marking messages as read via socket: $e');
    }
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
    try {
      print('Disposing socket connection');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      updateSocketConnectionStatus(false);
      _socketInitialized = false; // Also reset initialized flag on dispose
    } catch (e) {
      print('Error disposing socket: $e');
    }
  }

  // Manually set the token (for debugging/recovery)
  Future<bool> manuallySetToken(String token) async {
    try {
      print('Manually setting token: ${token.substring(0, math.min(10, token.length))}...');

      // Set in secure storage
      final secureResult = await _secureStorage.setToken(token);

      // Also set directly in shared prefs for extra safety
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);

      print('Manual token setting result - secure storage: $secureResult, prefs: ${prefs.containsKey('accessToken')}');

      // Verify token was set correctly by reading it back
      final savedToken = await _secureStorage.getToken();
      if (savedToken == token) {
        print('Token verification successful');
        return true;
      } else {
        print('WARNING: Token verification failed - saved value does not match');
        return false;
      }
    } catch (e) {
      print('Error manually setting token: $e');
      return false;
    }
  }
}
