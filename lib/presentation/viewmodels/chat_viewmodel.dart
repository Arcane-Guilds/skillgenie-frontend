import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
}

class ChatViewModel with ChangeNotifier {
  final ChatRepository _chatRepository;
  final SecureStorage _secureStorage;

  // Add this getter to check the socket connection status
  bool get isSocketConnected => _chatRepository.isSocketConnected;

  // State variables
  List<Chat> _chats = [];
  List<Message> _messages = [];
  Chat? _currentChat;
  String? _selectedChatId;
  bool _isLoading = false;
  bool _socketInitialized = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMoreMessages = true;
  Timer? _messageRefreshTimer;
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
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<Chat> get newChatStream => _newChatController.stream;

  MessageStatus? getMessageStatus(String messageId) => _messageStatus[messageId];

  // Constructor
  ChatViewModel({
    required ChatRepository chatRepository,
    required SecureStorage secureStorage,
  }) : _chatRepository = chatRepository,
        _secureStorage = secureStorage {
    _initialize();
  }

  Future<void> _initialize() async {
    
    _chatRepository.onNewMessage = _handleNewMessage as void Function(Message message)?;
    _chatRepository.onMessagesRead = _handleMessagesRead as void Function(String chatId, String userId)?;

    await _initializeSocket();

    _currentUserId = await _secureStorage.getUserId();
    print('ChatViewModel initialized with user ID: $_currentUserId');

    await loadChats();
    await refreshUnreadCounts();

    _setupMessageRefreshTimer();
  }

  Future<void> _initializeSocket() async {
    if (_socketInitialized) return;

    try {
      // Initialize socket connection
      await _chatRepository.initializeSocket();
      _socketInitialized = true;
      notifyListeners();

      // Check connection status periodically and reconnect if needed
      Timer.periodic(Duration(seconds: 15), (timer) {
        if (!_chatRepository.isSocketConnected) {
          print('Socket disconnected, attempting to reconnect...');
          _chatRepository.initializeSocket();
        }
      });
    } catch (e) {
      print('ChatViewModel: Error initializing socket: $e');
      _errorMessage = 'Failed to initialize real-time connection';
      notifyListeners();

      // Retry after delay if initialization fails
      Future.delayed(const Duration(seconds: 5), () {
        if (!_socketInitialized) {
          _initializeSocket();
        }
      });
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
    if (_currentChat == null || content.trim().isEmpty) return;

    try {
      // Create temporary message with local ID
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: _currentChat!.id,
        sender: User(
          id: _currentUserId!,
          username: '', // Will be filled in by server
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
        final success = await _chatRepository.sendMessageViaSocketWithTimeout(
          _currentChat!.id,
          content,
          timeout: Duration(seconds: 3),
        );

        if (success) {
          _messageStatus[tempMessage.id] = MessageStatus.sent;
          notifyListeners();
          print('Message sent successfully via socket');
        } else {
          throw Exception('Socket send timeout');
        }
      } catch (socketError) {
        print('Socket send failed, using REST API: $socketError');

        // Fall back to REST API if socket fails
        await _chatRepository.sendMessage(_currentChat!.id, content);
        _messageStatus[tempMessage.id] = MessageStatus.sent;
        notifyListeners();
      }

      // The message will appear in the next refresh or socket event
    } catch (e) {
      print('Error sending message: $e');

      // Mark the temporary message as failed
      final tempMessageIndex = _messages.indexWhere((m) => m.id.startsWith('temp_') && m.content == content);
      if (tempMessageIndex >= 0) {
        _messageStatus[_messages[tempMessageIndex].id] = MessageStatus.failed;
        notifyListeners();
      }

      _setError('Failed to send message: $e');
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

      // Add to stream for UI components that are listening specifically for new messages
      _newMessageController.add(message);

      // If this message belongs to the currently selected chat, add it to the messages list
      if (_currentChat?.id == message.chatId) {
        // Check if the message already exists in our list
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);

        if (existingIndex == -1) {
          // First, try to remove any temporary messages with the same content
          _removeTempMessage(message.content);

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
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
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

  void dispose() {
    _messageRefreshTimer?.cancel();
    _chatRepository.dispose();
    _newMessageController.close();
    _newChatController.close();
    super.dispose();
  }

  // Remove temporary message once the real one arrives
  void _removeTempMessage(String content) {
    // Find ALL temp messages with the same content (not just the first one)
    final tempIndices = <int>[];

    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].id.startsWith('temp_') && _messages[i].content == content) {
        tempIndices.add(i);
        print('  Found temporary message at index $i with content: $content');
      }
    }

    // Remove from last to first to avoid index shifting problems
    for (int i = tempIndices.length - 1; i >= 0; i--) {
      print('  Removing temporary message at index ${tempIndices[i]}');
      _messages.removeAt(tempIndices[i]);
    }
  }
}