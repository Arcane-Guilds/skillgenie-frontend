import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class SocketTestScreen extends StatefulWidget {
  const SocketTestScreen({Key? key}) : super(key: key);

  @override
  State<SocketTestScreen> createState() => _SocketTestScreenState();
}

class _SocketTestScreenState extends State<SocketTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _targetChatId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Force initialize socket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      if (!chatViewModel.socketInitialized) {
        _initializeSocket();
      }
    });
  }

  Future<void> _initializeSocket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication status
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (!authViewModel.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to use chat')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Initialize socket connection
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      await chatViewModel.refreshCurrentChat();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatViewModel.socketInitialized 
              ? 'Socket connected successfully!' 
              : 'Failed to connect socket'),
          backgroundColor: chatViewModel.socketInitialized ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _createChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Create chat with our own user ID for testing (self-chat)
      final currentUserId = authViewModel.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Test with a hardcoded user ID - replace with a valid user ID in your database
      const testUserId = '652e5431a77bced8e8cff2fb'; // Replace with a real user ID
      
      // Create the chat
      await chatViewModel.createChat(
        participants: [testUserId],
        isGroupChat: false,
      );
      
      // Store the chat ID
      setState(() {
        _targetChatId = chatViewModel.currentChat?.id ?? '';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat created: $_targetChatId')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat: $e')),
      );
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    if (_targetChatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a chat first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      
      // Select the chat first
      await chatViewModel.selectChat(_targetChatId);
      
      // Send the message
      await chatViewModel.sendMessage(message);
      
      // Clear the input
      _messageController.clear();
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final socketStatus = chatViewModel.isSocketConnected ? 'Connected' : 'Disconnected';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket Test'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    chatViewModel.isSocketConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: chatViewModel.isSocketConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    socketStatus,
                    style: TextStyle(
                      color: chatViewModel.isSocketConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Socket Status: $socketStatus',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('Current Chat ID: ${_targetChatId.isEmpty ? 'None' : _targetChatId}'),
                    Text('Total Chats: ${chatViewModel.chats.length}'),
                    Text('Messages: ${chatViewModel.messages.length}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _initializeSocket,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect Socket'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Test Chat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createChat,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Chat'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send Test Message',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a test message',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading && _targetChatId.isNotEmpty,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading || _targetChatId.isEmpty 
                          ? null 
                          : _sendMessage,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Message'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Messages',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: chatViewModel.messages.isEmpty
                            ? const Center(child: Text('No messages yet'))
                            : ListView.builder(
                                itemCount: chatViewModel.messages.length,
                                itemBuilder: (context, index) {
                                  final message = chatViewModel.messages[index];
                                  final messageStatus = chatViewModel.getMessageStatus(message.id);
                                  
                                  return ListTile(
                                    title: Text(message.content),
                                    subtitle: Text(
                                      '${message.sender.username} at ${message.createdAt.toString().substring(0, 16)}',
                                    ),
                                    trailing: messageStatus == MessageStatus.sending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : messageStatus == MessageStatus.failed
                                            ? const Icon(Icons.error, color: Colors.red)
                                            : const Icon(Icons.done, color: Colors.green),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 