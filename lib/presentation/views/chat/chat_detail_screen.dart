import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/chat_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';


class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    // Load chat data when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatViewModel>(context, listen: false).selectChat(widget.chatId);
    });

    // Add scroll listener to load more messages
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // We've reached the end of the current list, load more messages
      Provider.of<ChatViewModel>(context, listen: false).loadMessages();
    }
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    
    try {
      // Show sending indicator in UI by adding a temporary message
      final currentUserId = Provider.of<AuthViewModel>(context, listen: false).currentUser?.id;
      final currentUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;
      
      if (currentUserId == null || currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: User not authenticated')),
        );
        return;
      }
      
      // Optimistically add message to UI before getting server response
      // This is handled by the ViewModel now but we'll provide visual feedback
      setState(() {
        _isComposing = false;
      });
      
      // Clear input field immediately for better UX
      _messageController.clear();
      
      // Send the actual message
      chatViewModel.sendMessage(message);
      
      // Scroll to bottom to show new message
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
      
      // Debug log to confirm message was sent
      print('Message sent: $message');
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

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authViewModel.currentUser?.id ?? '';
    final chat = chatViewModel.currentChat;
    
    return Scaffold(
      appBar: AppBar(
        title: chat != null
            ? Text(chat.getDisplayName(currentUserId))
            : const Text('Chat'),
        actions: [
          // Debug button for token issues
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Debug Token',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('accessToken');
              
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No token found')),
                );
                return;
              }
              
              // Show a dialog with token info
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Token Debug'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Token: ${token.length > 20 ? token.substring(0, 20) + "..." : token}'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            
                            // Force token refresh
                            final success = await chatViewModel.forceTokenRefresh(token);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                  ? 'Token refresh successful' 
                                  : 'Token refresh failed'),
                              ),
                            );
                          },
                          child: const Text('Force Refresh Token'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (chat != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => chatViewModel.loadMessages(refresh: true),
            ),
        ],
      ),
      body: chat == null
          ? _buildLoadingOrError(chatViewModel)
          : Column(
              children: [
                Expanded(
                  child: _buildMessageList(chatViewModel, currentUserId),
                ),
                _buildMessageComposer(),
              ],
            ),
    );
  }

  Widget _buildLoadingOrError(ChatViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.selectChat(widget.chatId),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('No chat selected'));
  }

  Widget _buildMessageList(ChatViewModel viewModel, String currentUserId) {
    final messages = viewModel.messages;

    if (messages.isEmpty) {
      if (viewModel.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a message to start the conversation',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Display newest messages at the bottom
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length + (viewModel.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more messages
        if (viewModel.isLoading && index == messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final message = messages[index];
        final isOwnMessage = message.sender.id == currentUserId;
        
        // Add a small visual animation to highlight recently sent messages
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          child: _buildMessageItem(message, isOwnMessage),
        );
      },
    );
  }

  Widget _buildMessageItem(Message message, bool isOwnMessage) {
    final messageTime = message.createdAt;
    final timeString = DateFormat('HH:mm').format(messageTime);
    
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwnMessage && !message.isSystemMessage)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                child: Text(
                  message.sender.username,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: message.isSystemMessage
                    ? Colors.grey.shade200
                    : isOwnMessage
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: message.isSystemMessage ? FontStyle.italic : FontStyle.normal,
                      color: message.isSystemMessage ? Colors.grey.shade700 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (isOwnMessage)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Icon(
                            message.readBy.length > 1 
                                ? Icons.done_all 
                                : Icons.done,
                            size: 12,
                            color: message.readBy.length > 1
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
              ),
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: (text) {
                if (_isComposing) {
                  _handleSendMessage();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: _isComposing ? Colors.blue : Colors.grey,
            onPressed: _isComposing ? _handleSendMessage : null,
          ),
        ],
      ),
    );
  }
} 