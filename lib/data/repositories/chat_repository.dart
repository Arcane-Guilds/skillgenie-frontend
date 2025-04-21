import 'dart:convert';
import 'dart:async';
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
  bool _socketInitializing = false;
  
  // Socket reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  final String baseUrl = ApiConstants.baseUrl;

  // Callback functions for socket events
  Function(Map<String, dynamic>)? onNewChat;
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onMessagesRead;
  
  // Socket connection status
  bool get isSocketConnected => _socket?.connected ?? false;

  ChatRepository({
    required http.Client client,
    required SecureStorage secureStorage,
  }) : _client = client,
      _secureStorage = secureStorage;

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

  // Initialize socket connection with improved error handling and reconnection
  Future<bool> initializeSocket() async {
    // Prevent multiple simultaneous initialization attempts
    if (_socketInitializing) {
      print('Socket initialization already in progress, skipping');
      return false;
    }
    
    _socketInitializing = true;
    
    try {
      final token = await _secureStorage.getToken();
      if (token == null) {
        print('Cannot initialize socket: token is null');
        _socketInitializing = false;
        return false;
      }

      _currentUserId = await _secureStorage.getUserId();
      if (_currentUserId == null) {
        print('Cannot initialize socket: user ID is null');
        _socketInitializing = false;
        return false;
      }

      // Close existing socket if any
      _socket?.disconnect();
      _socket?.close();
      _socket = null;

      print('Initializing socket connection to $baseUrl/chat');
      
      // Create new socket connection with proper options
      _socket = io.io('$baseUrl/chat', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'auth': {'token': token},
        'forceNew': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'timeout': 20000,
      });

      // Set up event listeners
      _socket?.onConnect((_) {
        print('Socket connected successfully');
        _reconnectAttempts = 0; // Reset reconnect counter on successful connection
        _cancelReconnectTimer(); // Cancel any existing reconnect timer
      });

      _socket?.onConnectError((error) {
        print('Socket connection error: $error');
        _scheduleReconnect();
      });

      _socket?.onError((error) {
        print('Socket error: $error');
      });

      _socket?.onDisconnect((_) {
        print('Socket disconnected');
        _scheduleReconnect();
      });

      // Socket event handlers
      _setupSocketEventHandlers();
      
      // Connect to socket
      _socket?.connect();
      
      // Wait for connection to be established
      bool connected = false;
      final completer = Completer<bool>();
      
      // Listen for connection established
      _socket?.onConnect((_) {
        if (!completer.isCompleted) {
          connected = true;
          completer.complete(true);
        }
      });
      
      // Set timeout for connection
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(_socket?.connected ?? false);
        }
      });
      
      // Wait for connection or timeout
      final success = await completer.future;
      
      _socketInitializing = false;
      return success;
    } catch (e) {
      print('Error initializing socket: $e');
      _socketInitializing = false;
      return false;
    }
  }
  
  void _setupSocketEventHandlers() {
    _socket?.on('newChat', (data) {
      print('Received newChat event: $data');
      try {
        if (onNewChat != null) {
          onNewChat!(data);
        }
      } catch (e) {
        print('Error processing newChat event: $e');
      }
    });

    _socket?.on('newMessage', (data) {
      print('Received newMessage event: $data');
      try {
        if (onNewMessage != null) {
          onNewMessage!(data);
        }
      } catch (e) {
        print('Error processing newMessage event: $e');
      }
    });

    _socket?.on('messagesRead', (data) {
      print('Received messagesRead event: $data');
      try {
        if (onMessagesRead != null) {
          onMessagesRead!(data);
        }
      } catch (e) {
        print('Error processing messagesRead event: $e');
      }
    });
  }
  
  // Schedule socket reconnection
  void _scheduleReconnect() {
    // Cancel any existing timer
    _cancelReconnectTimer();
    
    // Only attempt reconnection if we haven't exceeded the max attempts
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      
      // Exponential backoff with a cap at 30 seconds
      final delay = Duration(
        milliseconds: math.min(
          1000 * math.pow(1.5, _reconnectAttempts).toInt(),
          const Duration(seconds: 30).inMilliseconds,
        ),
      );
      
      print('Scheduling socket reconnection attempt $_reconnectAttempts in ${delay.inSeconds} seconds');
      
      _reconnectTimer = Timer(delay, () {
        print('Attempting socket reconnection (attempt $_reconnectAttempts)');
        initializeSocket();
      });
    } else {
      print('Maximum reconnection attempts reached, giving up automatic reconnection');
    }
  }
  
  // Cancel reconnection timer
  void _cancelReconnectTimer() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
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
      final headers = await _getHeaders();
      
      final body = jsonEncode({
        'participants': participants,
        'isGroupChat': isGroupChat,
        if (name != null) 'name': name,
      });

      final response = await _client.post(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return Chat.fromJson(jsonData);
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}, reason: ${response.body}');
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

  // Send a message using socket with improved acknowledgment handling
  Future<bool> sendMessageViaSocket(
    String chatId, 
    String content, 
    {Duration timeout = const Duration(seconds: 5)}
  ) async {
    // Create a completer for tracking acknowledgment
    final completer = Completer<bool>();
    
    try {
      // First check if socket is connected
      if (_socket == null || !isSocketConnected) {
        print('Socket not connected, attempting to reconnect');
        
        // Try to initialize socket
        final reconnected = await initializeSocket();
        
        if (!reconnected) {
          print('FALLBACK: Unable to reconnect socket, falling back to REST API');
          await sendMessage(chatId, content);
          return true;
        }
      }
      
      // Prepare message data
      final messageData = {
        'chatId': chatId,
        'message': {'content': content},
      };
      
      print('Sending message via socket: "$content" to chat: $chatId');
      
      // Set up a one-time listener for message acknowledgment
      _socket?.once('messageSent', (data) {
        print('Message acknowledgement received from server: $data');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });
      
      // Set up a timeout for the acknowledgment
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          print('WARNING: Message acknowledgment timed out after ${timeout.inSeconds}s, falling back to REST API');
          
          // Fall back to REST API if socket acknowledgment times out
          sendMessage(chatId, content).then((_) {
            completer.complete(true);
          }).catchError((error) {
            print('REST fallback also failed: $error');
            completer.complete(false);
          });
        }
      });
      
      // Actually send the message
      _socket?.emit('sendMessage', messageData);
      
      // Wait for acknowledgment or timeout+fallback
      return await completer.future;
      
    } catch (e) {
      print('Error sending message via socket: $e');
      
      // Only try REST fallback if completer hasn't completed yet
      if (!completer.isCompleted) {
        try {
          print('FALLBACK: Using REST API after socket failure');
          await sendMessage(chatId, content);
          completer.complete(true);
        } catch (restError) {
          print('REST API fallback also failed: $restError');
          completer.complete(false);
        }
      }
      
      return await completer.future;
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
        throw Exception('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Mark messages as read using socket with fallback
  Future<void> markMessagesAsReadViaSocket(String chatId) async {
    if (isSocketConnected) {
      _socket?.emit('markAsRead', chatId);
    } else {
      print('Socket not connected, using REST API to mark messages as read');
      try {
        await markMessagesAsRead(chatId);
      } catch (e) {
        print('Error marking messages as read via REST fallback: $e');
      }
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
      return {'total': 0, 'byChatId': <String, int>{}};
    }
  }

  // Manually force reconnection of socket
  Future<bool> forceSocketReconnection() async {
    // Reset reconnect counter
    _reconnectAttempts = 0;
    
    // Cancel any pending reconnect timer
    _cancelReconnectTimer();
    
    // Reinitialize socket
    return await initializeSocket();
  }

  // Dispose socket connection
  void dispose() {
    _cancelReconnectTimer();
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
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
      
      return secureResult;
    } catch (e) {
      print('Error manually setting token: $e');
      return false;
    }
  }
} 