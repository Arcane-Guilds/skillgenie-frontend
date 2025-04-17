import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/secure_storage.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';


class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final SecureStorage _secureStorage;
  
  List<Chat> _chats = [];
  Chat? _currentChat;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  int _totalUnreadCount = 0;
  Map<String, int> _unreadCountByChat = {};
  
  // Getters
  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  ChatViewModel({
    required ChatRepository chatRepository,
    required SecureStorage secureStorage,
  }) : _chatRepository = chatRepository,
       _secureStorage = secureStorage {
    _initialize();
  }

  // Initialize the view model
  Future<void> _initialize() async {
    // Set callbacks for real-time updates
    _chatRepository.onNewChat = _handleNewChat;
    _chatRepository.onNewMessage = _handleNewMessage;
    _chatRepository.onMessagesRead = _handleMessagesRead;
    
    // Initialize socket connection
    await _chatRepository.initializeSocket();
    
    // Get current user ID
    _currentUserId = await _secureStorage.getUserId();
    
    // Load initial data
    await loadChats();
    await refreshUnreadCounts();
  }

  // Load user's chats
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

  // Load messages for the current chat
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
      
      // Mark messages as read
      await markMessagesAsRead(chatId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Select a chat to view
  Future<void> selectChat(String chatId) async {
    _setLoading(true);
    try {
      // Reset current state
      _currentChat = null;
      _messages = [];
      notifyListeners();
      
      // Load the chat
      _currentChat = await _chatRepository.getChat(chatId);
      notifyListeners();
      
      // Load messages for this chat
      await loadMessages(refresh: true);
      
      // Mark messages as read
      await markMessagesAsRead(chatId);
    } catch (e) {
      _setError('Failed to load chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new chat
  Future<void> createChat({
    required List<String> participants,
    bool isGroupChat = false,
    String? name,
  }) async {
    _setLoading(true);
    try {
      final newChat = await _chatRepository.createChat(
        participants: participants,
        isGroupChat: isGroupChat,
        name: name,
      );
      
      // Add the new chat to the list if it's not already there
      final existingIndex = _chats.indexWhere((chat) => chat.id == newChat.id);
      if (existingIndex >= 0) {
        _chats[existingIndex] = newChat;
      } else {
        _chats.add(newChat);
      }
      
      notifyListeners();
      
      // Select the new chat
      await selectChat(newChat.id);
    } catch (e) {
      _setError('Failed to create chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    if (_currentChat == null || content.trim().isEmpty) return;
    
    try {
      // Create a temporary ID for optimistic UI updates
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create a temporary message for immediate UI feedback
      if (_currentUserId != null) {
        final sender = User(
          id: _currentUserId!,
          username: 'You', // This will be replaced when the real message arrives
          email: '',
        );
        
        final tempMessage = Message(
          id: "temp_$tempId",
          chatId: _currentChat!.id,
          sender: sender,
          content: content,
          createdAt: DateTime.now(),
          readBy: [_currentUserId!],
          isSystemMessage: false,
        );
        
        // Add temporary message to the UI immediately
        _messages.insert(0, tempMessage);
        notifyListeners();
        
        // Use socket for real-time communication if connected
        print('Sending message: "$content" to chat: ${_currentChat!.id}');
        _chatRepository.sendMessageViaSocket(_currentChat!.id, content);
        
        // Also send via REST API as fallback if needed
        // This could be made conditional based on socket connection status
        try {
          await _chatRepository.sendMessage(_currentChat!.id, content);
          print('Message sent via REST API successfully');
        } catch (restError) {
          print('REST API message send failed, relying on socket: $restError');
          // We don't need to show an error here if the socket worked
        }
      } else {
        // No current user ID - this shouldn't happen in normal operation
        print('ERROR: Attempted to send message with no current user ID');
        _setError('Cannot send message: Not authenticated');
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error sending message: $e');
      _setError('Failed to send message: $e');
      
      // If we have error handling UI, we might want to mark the message as failed
      // For demonstration, we'll just print an error
      print('Message sending failed: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      // Use socket for real-time update
      _chatRepository.markMessagesAsReadViaSocket(chatId);
      
      // Also call the API for reliability
      await _chatRepository.markMessagesAsRead(chatId);
      
      // Update local unread count
      _updateUnreadCount(chatId, 0);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Refresh unread counts
  Future<void> refreshUnreadCounts() async {
    try {
      final unreadData = await _chatRepository.getUnreadMessageCount();
      _totalUnreadCount = unreadData['total'] ?? 0;
      _unreadCountByChat = Map<String, int>.from(unreadData['byChatId'] ?? {});
      
      // Update chat objects with unread counts
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

  // Handle new chat from socket
  void _handleNewChat(Chat chat) {
    // Add or update the chat in the list
    final existingIndex = _chats.indexWhere((c) => c.id == chat.id);
    if (existingIndex >= 0) {
      _chats[existingIndex] = chat;
    } else {
      _chats.add(chat);
    }
    
    notifyListeners();
  }

  // Handle new message from socket
  void _handleNewMessage(Message message) {
    // If the message is for the current chat, add it to messages
    if (_currentChat != null && message.chatId == _currentChat!.id) {
      _messages.insert(0, message);
      
      // Mark as read immediately if we're viewing this chat
      markMessagesAsRead(message.chatId);
    } else {
      // Otherwise, increment unread count
      _updateUnreadCount(message.chatId, (_unreadCountByChat[message.chatId] ?? 0) + 1);
    }
    
    // Update the chat's last message
    final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex >= 0) {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = Chat(
        id: chat.id,
        participants: chat.participants,
        name: chat.name,
        isGroupChat: chat.isGroupChat,
        admin: chat.admin,
        lastActivity: DateTime.now(),
        lastMessage: message,
        unreadCount: _currentChat?.id == message.chatId 
          ? 0 
          : (_unreadCountByChat[message.chatId] ?? 0),
      );
      
      // Move this chat to the top of the list (most recent)
      if (chatIndex > 0) {
        final updatedChat = _chats.removeAt(chatIndex);
        _chats.insert(0, updatedChat);
      }
    }
    
    notifyListeners();
  }

  // Handle messages read event from socket
  void _handleMessagesRead(String chatId, String userId) {
    // Only update UI if someone else is reading our messages
    if (_currentUserId != null && userId != _currentUserId!) {
      notifyListeners();
    }
  }

  // Update unread count
  void _updateUnreadCount(String chatId, int count) {
    final oldCount = _unreadCountByChat[chatId] ?? 0;
    _unreadCountByChat[chatId] = count;
    _totalUnreadCount = _totalUnreadCount - oldCount + count;
    
    // Update the chat object as well
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

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // Helper to set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear current error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Force token refresh or update for debugging
  Future<bool> forceTokenRefresh(String token) async {
    try {
      print('Forcing token refresh: ${token.substring(0, math.min(10, token.length))}...');
      
      // First, try to set it with the chat repository
      final result = await _chatRepository.manuallySetToken(token);
      
      // Also manually update secure storage
      await _secureStorage.forceSetToken(token);
      
      // Verify with direct SharedPreferences too
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      
      // Log the status
      print('Force token refresh completed, success: $result');
      
      // Attempt to reconnect socket with new token
      await _chatRepository.initializeSocket();
      
      return result;
    } catch (e) {
      print('Error during force token refresh: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _chatRepository.dispose();
    super.dispose();
  }
} 