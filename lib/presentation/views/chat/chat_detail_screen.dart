import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';


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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
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

    try {
      // Check if user is authenticated
      final currentUserId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.id;
      final currentUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;

      if (currentUserId == null || currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: User not authenticated')),
        );
        return;
      }

      // Update UI state
      setState(() {
        _isComposing = false;
      });

      // Clear input field immediately for better UX
      _messageController.clear();

      // Send the message
      chatViewModel.sendMessage(message);

      // Scroll to bottom to show the temporary message
      _scrollToBottom();
    } catch (e) {
      // Show error if message sending fails
      print('Failed to send message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => chatViewModel.sendMessage(message),
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    // Use a small delay to ensure UI has updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                      ? NetworkImage(chatRecipient.avatar!)
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
          if (!chatViewModel.isSocketConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Offline mode',
                child: Icon(
                  Icons.cloud_off,
                  color: Colors.red[300],
                ),
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

              final message = messages[index];
              final isCurrentUser = message.sender.id == _currentUserId;
              final messageStatus = chatViewModel.getMessageStatus(message.id);

              return _buildMessageItem(message, isCurrentUser, messageStatus, chatViewModel);
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
                    ? NetworkImage(message.sender.avatar!)
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
} 