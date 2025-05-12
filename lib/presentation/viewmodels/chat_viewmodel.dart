import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';
import 'auth/auth_viewmodel.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
}

class ChatViewModel with ChangeNotifier {
  final ChatRepository _chatRepository;
  final SecureStorage _secureStorage;
  final AuthViewModel _authViewModel;

  // Add this getter to check the socket connection status
  bool get isSocketConnected => _chatRepository.isSocketConnected;

  // State variables
  List<Chat> _chats = [];
  List<Message> _messages = [];
  Chat? _currentChat;
  String? _selectedChatId;
  bool _isLoading = false;
  bool _socketInitialized = false;
  bool _isConnecting = false;
  String? _errorMessage;
  final int _page = 1;
  final bool _hasMoreMessages = true;
  Timer? _messageRefreshTimer;
  Timer? _connectionCheckTimer;
  String? _currentUserId;
  int _totalUnreadCount = 0;
  Map<String, int> _unreadCountByChat = {};

  // Track message status (key: message ID, value: status)
  final Map<String, MessageStatus> _messageStatus = {};

  // Controllers for real-time events
  final StreamController<Message> _newMessageController = StreamController<Message>.broadcast();
  final StreamController<Chat> _newChatController = StreamController<Chat>.broadcast();

  // Getters
  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  Chat? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;
  bool get socketInitialized => _socketInitialized;
  bool get isConnecting => _isConnecting;
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<Chat> get newChatStream => _newChatController.stream;

  MessageStatus? getMessageStatus(String messageId) => _messageStatus[messageId];

  // Constructor
  ChatViewModel({
    required ChatRepository chatRepository,
    required SecureStorage secureStorage,
    required AuthViewModel authViewModel,
  }) : _chatRepository = chatRepository,
        _secureStorage = secureStorage,
        _authViewModel = authViewModel {
    _authViewModel.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  void _handleAuthChange() {
    final isAuthenticated = _authViewModel.isAuthenticated;
    final userId = _authViewModel.userId;
    
    print('ChatViewModel: Auth state changed - isAuthenticated: $isAuthenticated, userId: $userId');
    
    if (isAuthenticated && userId != null) {
      _currentUserId = userId;
      print('ChatViewModel: Setting currentUserId to $userId');
      
      // Call _initialize only if not already initialized and auth is complete
      if (!_socketInitialized && _authViewModel.authChecked) {
        _initialize();
      }
    } else if (!isAuthenticated) {
      // Cleanup only if previously initialized
      if (_socketInitialized) {
        print('ChatViewModel: Cleaning up due to logout or auth loss.');
        _chatRepository.dispose();
        _socketInitialized = false;
        _isConnecting = false;
        _chats = [];
        _messages = [];
        _currentChat = null;
        _messageRefreshTimer?.cancel();
        _connectionCheckTimer?.cancel();
        notifyListeners();
      }
    }
  }

  Future<void> _initialize() async {
    // Double check authentication status before proceeding
    if (!_authViewModel.isAuthenticated || _authViewModel.userId == null) {
      print('ChatViewModel: Initialize called but user is not authenticated. Aborting.');
      return;
    }

    if (_socketInitialized || _isConnecting) {
      print('ChatViewModel: Already initialized or connecting. Skipping initialization.');
      return;
    }

    print('ChatViewModel: Initializing...');
    _isConnecting = true;
    notifyListeners();

    try {
      // *** Ensure User ID is loaded FIRST ***
      await ensureCurrentUserId();
      if (_currentUserId == null) {
        throw Exception('Failed to retrieve current user ID during initialization.');
      }
      print('ChatViewModel: User ID confirmed: $_currentUserId');

      // Setup repository callbacks
      _chatRepository.onNewMessage = (message) {
        if (message is Map<String, dynamic>) {
          _handleNewMessage(message);
        } else if (message is Message) {
          _handleNewMessage(message.toJson());
        }
      };
      _chatRepository.onMessagesRead = (chatId, userId) {
        _handleMessagesRead({
          'chatId': chatId,
          'userId': userId,
        });
      };
      _chatRepository.onNewChat = (chat) {
        if (chat is Map<String, dynamic>) {
          _handleNewChat(chat);
        } else if (chat is Chat) {
          _handleNewChat(chat.toJson());
        }
      };
      _chatRepository.onConnectionStatusChanged = (bool isConnected) {
        print('ChatViewModel: Received connection status update: $isConnected');
        if (isConnected && !_socketInitialized) {
          _socketInitialized = true;
          _isConnecting = false;
          _setError(null);
          print('ChatViewModel: Socket marked as initialized and connected.');
          notifyListeners();
          loadChats();
          refreshUnreadCounts();
        } else if (!isConnected && _socketInitialized) {
          _socketInitialized = false;
          _isConnecting = false;
          _setError('Chat connection lost. Attempting to reconnect...');
          print('ChatViewModel: Socket marked as disconnected.');
          notifyListeners();
        } else if (isConnected && _socketInitialized) {
          print('ChatViewModel: Socket connection confirmed.');
          _setError(null);
          notifyListeners();
        }
      };

      // Attempt socket connection
      await _initializeSocket();

      // Load initial data
      await loadChats();
      await refreshUnreadCounts();

      // Start connection monitoring
      _setupConnectionCheckTimer();

    } catch (e) {
      print('ChatViewModel: Error during initialization: $e');
      _setError('Failed to initialize chat functionality.');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> _initializeSocket() async {
    if (_socketInitialized) {
       print('ChatViewModel: Socket already initialized.');
       return;
    }
    
    print('ChatViewModel: Attempting to initialize socket connection...');
    _setLoading(true);
    _isConnecting = true;
    
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('Cannot initialize socket: User ID not available.');
      }

      await _chatRepository.initializeSocket();
      
      print('ChatViewModel: Socket initialization initiated in repository.');

    } catch (e) {
      print('ChatViewModel: Error initializing socket: $e');
      _socketInitialized = false;
      _isConnecting = false;
      _setError('Failed to initialize chat connection: ${e.toString()}');
      notifyListeners();
    }
  }

  void _setupConnectionCheckTimer() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_authViewModel.isAuthenticated && !_isConnecting) {
        if (!_socketInitialized || (_socketInitialized && !_chatRepository.isSocketConnected)) {
          print('Connection check: Socket not connected or not initialized. Attempting to initialize/reconnect...');
          _initializeSocket();
        }
      }
    });
  }

  Future<void> reconnect() async {
    if (_isConnecting) return;
    
    _chatRepository.dispose();
    _socketInitialized = false;
    await _initializeSocket();
  }

  Future<bool> testConnection() async {
    try {
      if (!_socketInitialized || !_chatRepository.isSocketConnected) {
        print('Socket not initialized or not connected, attempting to reconnect first');
        await reconnect();
        // Wait briefly for reconnection to complete
        await Future.delayed(const Duration(seconds: 2));
      }
      
      if (!_chatRepository.isSocketConnected) {
        print('Socket still not connected after reconnect attempt');
        return false;
      }
      
      try {
        print('Sending ping to test connection');
        final completer = Completer<bool>();
        
        // Create a one-time listener for the pong response
        _chatRepository.onPong = (data) {
          print('Received pong response: $data');
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        };
        
        // Send ping
        _chatRepository.sendPing();
        
        // Wait for pong with timeout
        Timer(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            print('Ping timeout - no pong received');
            completer.complete(false);
          }
        });
        
        return await completer.future;
      } catch (e) {
        print('Error during ping test: $e');
        return false;
      }
    } catch (e) {
      print('Error in testConnection: $e');
      return false;
    }
  }

  void _setupMessageRefreshTimer() {
    _messageRefreshTimer?.cancel();

    _messageRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentChat != null && !_isLoading) {
        try {
          final latestMessages = await _chatRepository.getChatMessages(_currentChat!.id, limit: 10);

          if (latestMessages.isNotEmpty) {
            final existingIds = _messages.map((m) => m.id).toSet();
            final newMessages = latestMessages.where((m) => !existingIds.contains(m.id)).toList();

            if (newMessages.isNotEmpty) {
              _messages.insertAll(0, newMessages);
              markMessagesAsRead(_currentChat!.id);
              notifyListeners();
            }
          }
        } catch (e) {
          print('Error during periodic message refresh: $e');
        }
      }
    });
  }

  Future<void> loadChats() async {
    _setLoading(true);
    try {
      _chats = await _chatRepository.getUserChats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMessages({bool refresh = false}) async {
    if (_currentChat == null) return;

    _setLoading(true);
    try {
      final chatId = _currentChat!.id;
      if (refresh) {
        _messages = [];
      }

      final messages = await _chatRepository.getChatMessages(
        chatId,
        before: _messages.isNotEmpty ? _messages.last.id : null,
      );

      if (_messages.isEmpty) {
        _messages = messages;
      } else {
        _messages.addAll(messages);
      }

      await markMessagesAsRead(chatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentChat() async {
    if (_currentChat == null) return;

    try {
      final chatId = _currentChat!.id;
      final existingIds = _messages.map((m) => m.id).toSet();
      final latestMessages = await _chatRepository.getChatMessages(chatId, limit: 20);

      final newMessages = latestMessages.where((m) => !existingIds.contains(m.id)).toList();

      if (newMessages.isNotEmpty) {
        _messages.insertAll(0, newMessages);
        await markMessagesAsRead(chatId);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing current chat: $e');
    }
  }

  Future<void> selectChat(String chatId) async {
    _setLoading(true);
    try {
      _currentChat = null;
      _messages = [];
      notifyListeners();

      _currentChat = await _chatRepository.getChat(chatId);
      notifyListeners();

      await loadMessages(refresh: true);
      await markMessagesAsRead(chatId);
      _setupMessageRefreshTimer();
    } catch (e) {
      _setError('Failed to load chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createChat({
    required List<String> participants,
    bool isGroupChat = false,
    String? name,
  }) async {
    _setLoading(true);
    try {
      final existingChat = await _findExistingChat(participants, isGroupChat);
      if (existingChat != null) {
        _currentChat = existingChat;
        notifyListeners();
        await loadMessages(refresh: true);
        _setLoading(false);
        return;
      }

      final newChat = await _chatRepository.createChat(
        participants: participants,
        isGroupChat: isGroupChat,
        name: name,
      );

      final existingIndex = _chats.indexWhere((chat) => chat.id == newChat.id);
      if (existingIndex >= 0) {
        _chats[existingIndex] = newChat;
      } else {
        _chats.add(newChat);
      }

      _currentChat = newChat;
      notifyListeners();
      await loadMessages(refresh: true);
    } catch (e) {
      _setError('Failed to create chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Chat?> _findExistingChat(List<String> participants, bool isGroupChat) async {
    try {
      await loadChats();

      if (!isGroupChat && participants.length == 1) {
        final otherUserId = participants[0];

        for (final chat in _chats) {
          if (!chat.isGroupChat) {
            if (chat.participants.length == 2 &&
                chat.participants.any((p) => p.id == otherUserId || p == otherUserId)) {
              return chat;
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error finding existing chat: $e');
      return null;
    }
  }

  Future<String?> findOrCreateDirectChat(String userId) async {
    try {
      final existingChat = await _findExistingChat([userId], false);
      if (existingChat != null) {
        return existingChat.id;
      }

      await createChat(participants: [userId]);
      return _currentChat?.id;
    } catch (e) {
      print('Error in findOrCreateDirectChat: $e');
      return null;
    }
  }

  Future<void> sendMessage(String content) async {
    if (_currentChat == null || content.trim().isEmpty) {
      throw Exception('Cannot send message: Chat not selected or empty message');
    }
    
    // Ensure we have a current user ID
    if (_currentUserId == null) {
      await ensureCurrentUserId();
      
      if (_currentUserId == null) {
        print('Cannot send message: _currentUserId is still null after retry');
        _setError('Cannot send message: Not authenticated');
        throw Exception('Cannot send message: Not authenticated');
      }
    }

    try {
      // Generate a unique temp ID for the message
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';

      // Create temporary message with local ID
      final tempMessage = Message(
        id: tempId,
        chatId: _currentChat!.id,
        sender: User(
          id: _currentUserId!,
          username: 'Me', // Use a placeholder name until server response
          email: '',
        ),
        content: content,
        readBy: [_currentUserId!],
        isSystemMessage: false,
        createdAt: DateTime.now(),
      );

      // Add temporary message to UI for immediate feedback
      _messages.insert(0, tempMessage);
      _messageStatus[tempMessage.id] = MessageStatus.sending;
      notifyListeners();

      // Send message through socket
      try {
        print('Attempting to send message via socket: $content, tempId: $tempId');
        
        final success = await _chatRepository.sendMessageViaSocketWithTimeout(
          _currentChat!.id,
          content,
          tempId: tempId, // Pass the tempId to help with matching
          timeout: const Duration(seconds: 3),
        );

        if (success) {
          _messageStatus[tempMessage.id] = MessageStatus.sent;
          notifyListeners();
          print('Message sent successfully via socket, temp message status updated');
        } else {
          throw Exception('Socket send timeout');
        }
      } catch (socketError) {
        print('Socket send failed, using REST API: $socketError');

        // Fall back to REST API if socket fails
        final newMessage = await _chatRepository.sendMessage(_currentChat!.id, content);
        
        // If REST API call succeeded, remove the temporary message since we'll get the real one
        if (newMessage != null) {
          // Find and remove temporary message
          final tempIndex = _messages.indexWhere((m) => m.id == tempId);
          if (tempIndex >= 0) {
            _messages.removeAt(tempIndex);
          }
          
          // Add the official message from the server
          _messages.insert(0, newMessage);
          notifyListeners();
          print('Message sent successfully via REST API, temp message replaced');
        } else {
          // Just mark temp message as sent if we don't have a real one
          _messageStatus[tempMessage.id] = MessageStatus.sent;
          notifyListeners();
        }
      }

      // The message will appear in the next refresh or socket event
    } catch (e) {
      print('Error sending message: $e');

      // Find matching temporary message by content
      final tempMessageIndex = _messages.indexWhere((m) => 
        m.id.startsWith('temp_') && 
        m.content == content && 
        m.sender.id == _currentUserId
      );
      
      if (tempMessageIndex >= 0) {
        _messageStatus[_messages[tempMessageIndex].id] = MessageStatus.failed;
        notifyListeners();
      }

      _setError('Failed to send message: $e');
      throw e; // Re-throw the error to be caught by the UI
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      _chatRepository.markMessagesAsReadViaSocket(chatId);
      await _chatRepository.markMessagesAsRead(chatId);
      _updateUnreadCount(chatId, 0);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> refreshUnreadCounts() async {
    try {
      final unreadData = await _chatRepository.getUnreadMessageCount();
      _totalUnreadCount = unreadData['total'] ?? 0;
      _unreadCountByChat = Map<String, int>.from(unreadData['byChatId'] ?? {});

      for (int i = 0; i < _chats.length; i++) {
        final chatId = _chats[i].id;
        if (_unreadCountByChat.containsKey(chatId)) {
          final chat = _chats[i];
          _chats[i] = Chat(
            id: chat.id,
            participants: chat.participants,
            name: chat.name,
            isGroupChat: chat.isGroupChat,
            admin: chat.admin,
            lastActivity: chat.lastActivity,
            lastMessage: chat.lastMessage,
            unreadCount: _unreadCountByChat[chatId] ?? 0,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error refreshing unread counts: $e');
    }
  }

  void _handleNewChat(Map<String, dynamic> data) {
    try {
      print('New chat received: $data');
      final chat = Chat.fromJson(data);

      final existingIndex = _chats.indexWhere((c) => c.id == chat.id);
      if (existingIndex >= 0) {
        _chats[existingIndex] = chat;
      } else {
        _chats.insert(0, chat);
      }
      notifyListeners();

      // Push to stream for more specific listeners
      _newChatController.add(chat);
    } catch (e) {
      print('Error handling new chat: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      print('New message received: $data');
      final message = Message.fromJson(data);

      // Extract tempId from the data if present
      final tempId = data['tempId'] as String?;
      print('Message tempId from server: $tempId');

      // Add to stream for UI components that are listening specifically for new messages
      _newMessageController.add(message);

      // If this message belongs to the currently selected chat, add it to the messages list
      if (_currentChat?.id == message.chatId) {
        // First check if there's a tempId to match
        bool tempMessageRemoved = false;
        if (tempId != null && tempId.isNotEmpty) {
          // Try to find and remove the temporary message with matching tempId
          final tempIndex = _messages.indexWhere((m) => m.id == tempId);
          if (tempIndex >= 0) {
            print('Found and removing temporary message with matching tempId: $tempId');
            _messages.removeAt(tempIndex);
            tempMessageRemoved = true;
          }
        }

        // If no match by tempId, check for matching content from current user
        if (!tempMessageRemoved && message.sender.id == _currentUserId) {
          // Look for temporary messages with matching content
          final tempIndices = <int>[];
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].id.startsWith('temp_') &&
                _messages[i].content == message.content &&
                _messages[i].sender.id == message.sender.id) {
              tempIndices.add(i);
              print('Found temporary message at index $i with matching content: ${message.content}');
            }
          }

          // Remove temp messages from last to first to avoid index shifting issues
          for (int i = tempIndices.length - 1; i >= 0; i--) {
            print('Removing temporary message at index ${tempIndices[i]}');
            _messages.removeAt(tempIndices[i]);
            tempMessageRemoved = true;
          }
        }

        // Check if the message already exists to avoid duplicates
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          // Add new message to the list
          _messages.insert(0, message);

          // Mark the new message as read if it's from someone else
          if (message.sender.id != _currentUserId) {
            markMessagesAsRead(message.chatId);
          }

          // Notify listeners to update UI
          notifyListeners();
        }
      } else {
        // Message is for a different chat, increment unread count
        final chatId = message.chatId;
        final currentCount = _unreadCountByChat[chatId] ?? 0;
        _updateUnreadCount(chatId, currentCount + 1);
      }

      // Update the chat's last message
      final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
      if (chatIndex >= 0) {
        final chat = _chats[chatIndex];
        final updatedChat = Chat(
          id: chat.id,
          participants: chat.participants,
          name: chat.name,
          isGroupChat: chat.isGroupChat,
          admin: chat.admin,
          lastActivity: DateTime.now(),
          lastMessage: message,
          unreadCount: _currentChat?.id == message.chatId
              ? 0
              : (_unreadCountByChat[message.chatId] ?? 0) + 1,
        );

        // Remove from current position
        _chats.removeAt(chatIndex);

        // Add back at the beginning (most recent)
        _chats.insert(0, updatedChat);

        // If this is the current chat, update the reference
        if (_currentChat?.id == updatedChat.id) {
          _currentChat = updatedChat;
        }

        // Notify UI of change
        notifyListeners();
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'];
      final userId = data['userId'];
      final messageIds = List<String>.from(data['messageIds'] ?? []);

      if (_currentUserId != null && userId != _currentUserId) {
        if (_currentChat?.id == chatId) {
          bool updated = false;

          for (int i = 0; i < _messages.length; i++) {
            final message = _messages[i];

            if (message.sender.id == _currentUserId &&
                (messageIds.isEmpty || messageIds.contains(message.id)) &&
                !message.readBy.contains(userId)) {

              final updatedReadBy = List<String>.from(message.readBy)..add(userId);
              _messages[i] = Message(
                id: message.id,
                chatId: message.chatId,
                sender: message.sender,
                content: message.content,
                createdAt: message.createdAt,
                readBy: updatedReadBy,
                isSystemMessage: message.isSystemMessage,
              );

              updated = true;
            }
          }

          if (updated) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error handling messages read: $e');
    }
  }

  void _updateUnreadCount(String chatId, int count) {
    final oldCount = _unreadCountByChat[chatId] ?? 0;
    _unreadCountByChat[chatId] = count;
    _totalUnreadCount = _totalUnreadCount - oldCount + count;

    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex >= 0) {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = Chat(
        id: chat.id,
        participants: chat.participants,
        name: chat.name,
        isGroupChat: chat.isGroupChat,
        admin: chat.admin,
        lastActivity: chat.lastActivity,
        lastMessage: chat.lastMessage,
        unreadCount: count,
      );
    }

    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
       _errorMessage = null;
    } else {
       _isConnecting = false;
    }
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    if (message != null) {
      _isConnecting = false;
      _isLoading = false;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> forceTokenRefresh(String token) async {
    try {
      final result = await _chatRepository.manuallySetToken(token);
      await _secureStorage.forceSetToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      await _chatRepository.initializeSocket();
      return result;
    } catch (e) {
      print('Error during force token refresh: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _messageRefreshTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _chatRepository.dispose();
    _newMessageController.close();
    _newChatController.close();
    _authViewModel.removeListener(_handleAuthChange);
    super.dispose();
  }

  // Helper method to ensure we have the current user ID from all possible sources
  Future<void> ensureCurrentUserId() async {
    if (_currentUserId != null) return;
    
    print('ChatViewModel: Attempting to ensure currentUserId is set');
    
    // Try from AuthViewModel first
    _currentUserId = _authViewModel.userId;
    if (_currentUserId != null) {
      print('ChatViewModel: Got userId from AuthViewModel: $_currentUserId');
      return;
    }
    
    // Try from SharedPreferences/secure storage
    _currentUserId = await _secureStorage.getUserId();
    if (_currentUserId != null) {
      print('ChatViewModel: Got userId from SecureStorage: $_currentUserId');
      return;
    }
    
    // Try from AuthViewModel currentUser object
    if (_authViewModel.currentUser != null) {
      _currentUserId = _authViewModel.currentUser!.id;
      print('ChatViewModel: Got userId from AuthViewModel.currentUser: $_currentUserId');
      return;
    }
    
    // Try directly from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdFromPrefs = prefs.getString('user_id') ?? prefs.getString('userId');
      if (userIdFromPrefs != null && userIdFromPrefs.isNotEmpty) {
        _currentUserId = userIdFromPrefs;
        print('ChatViewModel: Got userId directly from SharedPreferences: $_currentUserId');
        return;
      }
      
      // Try to get it from the user object in SharedPreferences
      final userJson = prefs.getString("user");
      if (userJson != null) {
        try {
          final userObj = json.decode(userJson);
          _currentUserId = userObj['id'] ?? userObj['_id'];
          if (_currentUserId != null) {
            print('ChatViewModel: Extracted userId from user JSON: $_currentUserId');
            return;
          }
        } catch (e) {
          print('ChatViewModel: Error parsing user JSON: $e');
        }
      }
    } catch (e) {
      print('ChatViewModel: Error getting userId from SharedPreferences: $e');
    }
    
    print('ChatViewModel: CRITICAL - Could not get userId from any source');
  }

  // Getter for current user ID that ensures it's loaded
  Future<String?> getCurrentUserId() async {
    if (_currentUserId == null) {
      await ensureCurrentUserId();
    }
    return _currentUserId;
  }
}