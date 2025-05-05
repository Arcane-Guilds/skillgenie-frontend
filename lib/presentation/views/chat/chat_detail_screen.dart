import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';


class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  String? _currentUserId;
  bool _isFirstLoad = true;
  final DateTime _lastRefreshTime = DateTime.now();
  Timer? _autoRefreshTimer;
  StreamSubscription? _newMessageSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();

    // Load chat data when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      viewModel.selectChat(widget.chatId);

      // Set up auto-refresh timer
      _setupAutoRefreshTimer();

      // Listen for new messages
      _listenForNewMessages();
    });

    // Add scroll listener to load more messages
    _scrollController.addListener(_onScroll);
  }

  void _listenForNewMessages() {
    final viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _newMessageSubscription = viewModel.newMessageStream.listen((message) {
      if (message.chatId == widget.chatId && mounted) {
        // Force refresh when we receive a new message
        print('New message received via stream for current chat: ${message.content}');
        setState(() {});

        // If the new message is not from the current user, mark it as read
        if (message.sender.id != _currentUserId) {
          viewModel.markMessagesAsRead(widget.chatId);
        }

        // Scroll to bottom to show new message if we're near the bottom
        _scrollToBottomIfNeeded();
      }
    });
  }

  void _scrollToBottomIfNeeded() {
    if (!_scrollController.hasClients) return;

    // Only auto-scroll if user is already near the bottom
    final currentPosition = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;

    // If we're within 300 pixels of the bottom, auto-scroll
    if (maxExtent - currentPosition < 300) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setupAutoRefreshTimer() {
    // Cancel any existing timer
    _autoRefreshTimer?.cancel();

    // Create a new timer that refreshes messages every 5 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _silentRefresh();
      }
    });
  }

  Future<void> _silentRefresh() async {
    try {
      if (!mounted) return;

      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      await viewModel.refreshCurrentChat();

      // Check if there are any pending messages and update UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Silent refresh error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    _newMessageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    print('ChatDetailScreen: Attempting to load current user ID');
    
    // Try from AuthViewModel first (most reliable source)
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.userId;
    
    if (userId != null && userId.isNotEmpty) {
      print('ChatDetailScreen: Got userId from AuthViewModel: $userId');
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
      }
      return;
    }
    
    // Try from SharedPreferences as fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try multiple possible keys
      String? userIdFromPrefs;
      for (final key in ['userId', 'user_id', 'id']) {
        userIdFromPrefs = prefs.getString(key);
        if (userIdFromPrefs != null && userIdFromPrefs.isNotEmpty) {
          print('ChatDetailScreen: Got userId from SharedPreferences key "$key": $userIdFromPrefs');
          break;
        }
      }
      
      // If still null, try to extract from user object
      if (userIdFromPrefs == null) {
        final userJson = prefs.getString('user');
        if (userJson != null) {
          try {
            final userMap = json.decode(userJson);
            userIdFromPrefs = userMap['id'] ?? userMap['_id'];
            print('ChatDetailScreen: Extracted userId from user JSON: $userIdFromPrefs');
          } catch (e) {
            print('ChatDetailScreen: Error parsing user JSON: $e');
          }
        }
      }
      
      if (userIdFromPrefs != null && mounted) {
        setState(() {
          _currentUserId = userIdFromPrefs;
        });
      } else {
        print('ChatDetailScreen: WARNING - Could not find userId in SharedPreferences');
      }
    } catch (e) {
      print('ChatDetailScreen: Error loading user ID: $e');
    }
    
    // Last resort - try to get from ChatViewModel
    if (_currentUserId == null && mounted) {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.ensureCurrentUserId();
      
      final userId = await chatViewModel.getCurrentUserId();
      if (userId != null && mounted) {
        setState(() {
          _currentUserId = userId;
        });
        print('ChatDetailScreen: Got userId from ChatViewModel: $_currentUserId');
      }
    }
    
    if (_currentUserId == null) {
      print('ChatDetailScreen: CRITICAL - Failed to get userId from any source');
    } else {
      print('ChatDetailScreen: Successfully loaded userId: $_currentUserId');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final viewModel = Provider.of<ChatViewModel>(context, listen: false);
      if (!viewModel.isLoading && viewModel.messages.isNotEmpty) {
        viewModel.loadMessages(refresh: false);
      }
    }
  }

  Future<void> _refreshMessages() async {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing messages...'),
        duration: Duration(seconds: 1),
      ),
    );

    await chatViewModel.refreshCurrentChat();

    // Scroll to bottom after messages are refreshed
    if (_scrollController.hasClients && chatViewModel.messages.isNotEmpty) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    try {
      // Check if user is authenticated
      final currentUserId = authViewModel.currentUser?.id;
      final currentUser = authViewModel.currentUser;

      if (currentUserId == null || currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot send message: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verify current chat is properly loaded
      if (chatViewModel.currentChat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot send message: Chat not loaded properly'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update UI state
      setState(() {
        _isComposing = false;
      });

      // Store message text before clearing
      final messageText = message;
      
      // Clear input field immediately for better UX
      _messageController.clear();

      // Send the message
      chatViewModel.sendMessage(messageText).catchError((error) {
        // Handle any errors from the sendMessage method
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Put the text back in the input field
                _messageController.text = messageText;
                setState(() {
                  _isComposing = true;
                });
              },
            ),
          ),
        );
      });

      // Check connection status
      if (!chatViewModel.isSocketConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You are offline. Messages will be sent when you reconnect.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Force reconnection attempt
                chatViewModel.reconnect();
              },
            ),
          ),
        );
      }

      // Scroll to bottom after sending a message
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error in _handleSendMessage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markMessagesAsRead(ChatViewModel viewModel) {
    // Mark messages as read
    if (_isFirstLoad && viewModel.currentChat != null) {
      _isFirstLoad = false;
      viewModel.markMessagesAsRead(widget.chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final chat = chatViewModel.currentChat;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = _currentUserId ?? authViewModel.currentUser?.id;

    // Mark messages as read if we're viewing the chat
    _markMessagesAsRead(chatViewModel);

    // Get chat recipient for direct chats
    User? chatRecipient;
    if (chat != null && !chat.isGroupChat && currentUserId != null) {
      // Find the other user in the chat
      chatRecipient = chat.participants.firstWhere(
            (user) => user.id != currentUserId,
        orElse: () => chat.participants.first,
      );
    }

    // Choose the display name based on chat type
    String displayName = '';
    if (chat != null) {
      if (chat.isGroupChat) {
        displayName = chat.name ?? 'Group Chat';
      } else if (chatRecipient != null) {
        displayName = chatRecipient.username;
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (chat != null && !chat.isGroupChat) // Show avatar for direct chats
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: chatRecipient?.avatar != null && chatRecipient!.avatar!.isNotEmpty
                      ? (chatRecipient.avatar!.startsWith('http')
                      ? NetworkImage(chatRecipient.avatar!)
                      : AssetImage('assets/images/${chatRecipient.avatar}.png'))
                      : null,
                  child: (chatRecipient?.avatar == null || chatRecipient!.avatar!.isEmpty)
                      ? Text(
                    chatRecipient?.username.isNotEmpty == true
                        ? chatRecipient!.username[0].toUpperCase()
                        : '?',
                  )
                      : null,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Add debug button to test socket
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: Colors.grey[600],
            ),
            tooltip: 'Test Connection',
            onPressed: () {
              _testSocketConnection(context);
            },
          ),
          if (!chatViewModel.isSocketConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.sync_problem,
                  color: Colors.amber[300],
                ),
                tooltip: 'Reconnect to chat',
                onPressed: () => chatViewModel.reconnect(),
              ),
            ),
        ],
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          // Add a subtle pattern or gradient background
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor,
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside input area
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              // Add connection status banner at the top
              _buildConnectionStatusBanner(),
              
              Expanded(
                child: _buildMessageList(chatViewModel),
              ),
              _buildInputArea(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatViewModel chatViewModel) {
    if (chatViewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${chatViewModel.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => chatViewModel.refreshCurrentChat(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatViewModel.isLoading && chatViewModel.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final messages = chatViewModel.messages;

    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Send a message to start the conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshMessages,
          child: ListView.builder(
            controller: _scrollController,
            reverse: true, // Display newest messages at the bottom
            itemCount: messages.length + (chatViewModel.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (chatViewModel.isLoading && index == messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              try {
                final message = messages[index];
                final isCurrentUser = message.sender.id == _currentUserId;
                final messageStatus = chatViewModel.getMessageStatus(message.id);

                return _buildMessageItem(message, isCurrentUser, messageStatus, chatViewModel);
              } catch (e) {
                // Handle any null errors in messages
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Message Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'There was an error displaying this message: $e',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => chatViewModel.refreshCurrentChat(),
                            child: const Text('Refresh Messages'),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(Message message, bool isCurrentUser, MessageStatus? messageStatus, ChatViewModel chatViewModel) {
    final timeFormatted = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final isTemp = message.id.startsWith('temp_');
    final isFailed = messageStatus == MessageStatus.failed;
    final isGroupChat = chatViewModel.currentChat?.isGroupChat ?? false;

    // Alignment and styling configuration
    final bubbleColor = isCurrentUser
        ? (isFailed ? Colors.red[100] : Theme.of(context).primaryColor)
        : Colors.grey[200];
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sender avatar (left side for received messages)
          if (!isCurrentUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: message.sender.avatar != null
                    ? (message.sender.avatar!.startsWith('http')
                    ? NetworkImage(message.sender.avatar!)
                    : AssetImage('assets/images/${message.sender.avatar}.png'))
                    : null,
                child: message.sender.avatar == null
                    ? Text(message.sender.username[0])
                    : null,
              ),
            ),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Group name for received messages
                  if (isGroupChat && !isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender.username,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(color: textColor),
                  ),
                  // Timestamp and status
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          if (isTemp || messageStatus == MessageStatus.sending)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white70),
                              ),
                            )
                          else if (isFailed)
                            Icon(Icons.error_outline, size: 14, color: Colors.red[700])
                          else
                            const Icon(Icons.done_all, size: 14, color: Colors.white70)
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Spacer for sent messages
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
  Widget _buildInputArea(BuildContext context) {
    // If chat isn't loaded, or if there's no current user, disable input
    final authViewModel = Provider.of<AuthViewModel>(context);
    final chatViewModel = Provider.of<ChatViewModel>(context);

    final canSendMessages =
        chatViewModel.currentChat != null &&
            authViewModel.isAuthenticated &&
            !chatViewModel.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSendMessages,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: canSendMessages ? 'Type a message...' : 'Loading chat...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            disabledColor: Colors.grey[400],
            onPressed: canSendMessages && _isComposing
                ? _handleSendMessage
                : null,
          ),
        ],
      ),
    );
  }

  // Add a connection status indicator banner
  Widget _buildConnectionStatusBanner() {
    return Consumer<ChatViewModel>(
      builder: (context, chatViewModel, child) {
        if (chatViewModel.isConnecting) {
          return Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: const Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                SizedBox(width: 8),
                Text('Connecting to chat...', style: TextStyle(color: Colors.amber, fontSize: 12)),
              ],
            ),
          );
        } else if (!chatViewModel.isSocketConnected) {
          return Container(
            color: Colors.red.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_off, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('You are offline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => chatViewModel.reconnect(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        minimumSize: const Size(80, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('RECONNECT', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Messages will be sent when you reconnect. Your network connection may be unstable.',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink(); // No banner when connected
        }
      },
    );
  }

  // Add a method to test socket connection and show diagnostic info
  void _testSocketConnection(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    // Show dialog with connection status information
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Socket Connection Test'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connected: ${chatViewModel.isSocketConnected ? 'Yes ✅' : 'No ❌'}'),
                Text('Connecting: ${chatViewModel.isConnecting ? 'Yes' : 'No'}'),
                const SizedBox(height: 16),
                const Text('Connection Test:'),
                FutureBuilder(
                  future: chatViewModel.testConnection(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Testing connection...')
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final success = snapshot.data as bool? ?? false;
                      return Text(
                        success 
                          ? 'Ping test successful! Server responded. ✅' 
                          : 'Ping test failed. No response from server. ❌',
                        style: TextStyle(
                          color: success ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Connection Details:'),
                const SizedBox(height: 8),
                const Text('Socket URL: Check console logs for complete details'),
                const SizedBox(height: 8),
                Text('API Base URL: ${ApiConstants.baseUrl}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Refresh the dialog
                  chatViewModel.reconnect();
                },
                child: const Text('Retry Connection'),
              ),
            ],
          );
        }
      ),
    );
  }
} 