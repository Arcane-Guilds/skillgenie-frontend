import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../data/models/chat_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'chat_detail_screen.dart';
import 'create_chat_screen.dart';


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Load chats when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatViewModel>(context, listen: false).loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authViewModel.currentUser?.id ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => chatViewModel.loadChats(),
          ),
        ],
      ),
      body: _buildBody(chatViewModel, currentUserId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateChat(context),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildBody(ChatViewModel viewModel, String currentUserId) {
    if (viewModel.isLoading && viewModel.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadChats(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (viewModel.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a new chat with your friends',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateChat(context),
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadChats,
      child: ListView.builder(
        itemCount: viewModel.chats.length,
        itemBuilder: (context, index) {
          final chat = viewModel.chats[index];
          return _buildChatListTile(context, chat, currentUserId);
        },
      ),
    );
  }

  Widget _buildChatListTile(BuildContext context, Chat chat, String currentUserId) {
    final displayName = chat.getDisplayName(currentUserId);
    final lastMessageTime = chat.lastActivity;
    final now = DateTime.now();
    
    String timeText;
    if (lastMessageTime.day == now.day && 
        lastMessageTime.month == now.month && 
        lastMessageTime.year == now.year) {
      // Today, show time
      timeText = DateFormat('HH:mm').format(lastMessageTime);
    } else if (now.difference(lastMessageTime).inDays < 7) {
      // Within a week, show day name
      timeText = DateFormat('EEEE').format(lastMessageTime);
    } else {
      // Older, show date
      timeText = DateFormat('MMM d').format(lastMessageTime);
    }

    // Last message preview
    String messagePreview = '';
    if (chat.lastMessage != null) {
      final isOwnMessage = chat.lastMessage!.sender.id == currentUserId;
      final prefix = isOwnMessage ? 'You: ' : '';
      messagePreview = '$prefix${chat.lastMessage!.content}';
      
      // Truncate long messages
      if (messagePreview.length > 40) {
        messagePreview = '${messagePreview.substring(0, 40)}...';
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: chat.getDisplayAvatar(currentUserId) != null
            ? NetworkImage(chat.getDisplayAvatar(currentUserId)!)
            : null,
        child: chat.getDisplayAvatar(currentUserId) == null
            ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              messagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black : Colors.grey,
                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _navigateToChatDetail(context, chat.id),
    );
  }

  void _navigateToChatDetail(BuildContext context, String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chatId),
      ),
    );
  }

  void _navigateToCreateChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChatScreen(),
      ),
    );
  }
} 