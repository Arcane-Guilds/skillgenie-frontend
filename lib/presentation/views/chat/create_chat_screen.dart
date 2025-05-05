import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';


class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({Key? key}) : super(key: key);

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isGroupChat = false;
  final List<String> _selectedUserIds = [];
  bool _isCreatingChat = false;

  @override
  void initState() {
    super.initState();
    // Load friends when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendViewModel>(context, listen: false).loadFriends();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    if (_isGroupChat && _groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() {
      _isCreatingChat = true;
    });

    try {
      await Provider.of<ChatViewModel>(context, listen: false).createChat(
        participants: _selectedUserIds,
        isGroupChat: _isGroupChat,
        name: _isGroupChat ? _groupNameController.text.trim() : null,
      );
      
      if (mounted) {
        // Pop back to the chat detail screen (which should now show the new chat)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });
      }
    }
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupChat ? 'New Group Chat' : 'New Chat'),
        actions: [
          Switch(
            value: _isGroupChat,
            onChanged: (value) {
              setState(() {
                _isGroupChat = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text('Group'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isGroupChat)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child: _buildFriendsList(),
          ),
          _buildSelectedUsers(),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendViewModel>(
      builder: (context, friendViewModel, child) {
        if (friendViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendViewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(friendViewModel.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => friendViewModel.loadFriends(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (friendViewModel.friends.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Add friends to start a conversation',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: friendViewModel.friends.length,
          itemBuilder: (context, index) {
            final friend = friendViewModel.friends[index];
            final isSelected = _selectedUserIds.contains(friend.id);
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: friend.avatar != null
                    ? NetworkImage(friend.avatar!)
                    : null,
                child: friend.avatar == null
                    ? Text(friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?')
                    : null,
              ),
              title: Text(friend.username),
              subtitle: Text(friend.email),
              trailing: Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleUser(friend.id),
              ),
              onTap: () => _toggleUser(friend.id),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedUsers() {
    if (_selectedUserIds.isEmpty) {
      return Container();
    }

    return Consumer<FriendViewModel>(
      builder: (context, friendViewModel, child) {
        final selectedFriends = friendViewModel.friends
            .where((friend) => _selectedUserIds.contains(friend.id))
            .toList();

        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Selected (${selectedFriends.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedFriends.length,
                  itemBuilder: (context, index) {
                    final friend = selectedFriends[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: friend.avatar != null
                                    ? NetworkImage(friend.avatar!)
                                    : null,
                                child: friend.avatar == null
                                    ? Text(friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?')
                                    : null,
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () => _toggleUser(friend.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              friend.username,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCreatingChat ? null : _createChat,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          child: _isCreatingChat
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(_isGroupChat ? 'Create Group Chat' : 'Start Chat'),
        ),
      ),
    );
  }
} 