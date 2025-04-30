import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../../data/models/user_model.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({Key? key}) : super(key: key);

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isGroupChat = false;
  final List<String> _selectedUserIds = [];
  bool _isCreatingChat = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load friends when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendViewModel>(context, listen: false).loadFriends();
    });
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
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
          Row(
            children: [
              Text(_isGroupChat ? 'Group' : 'Direct'),
              Switch(
                value: _isGroupChat,
                onChanged: (value) {
                  setState(() {
                    _isGroupChat = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Group Name Field (if group chat)
          if (_isGroupChat)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
              ),
            ),
            
          // Selected Users Chips
          if (_selectedUserIds.isNotEmpty)
            _buildSelectedUsersChips(),
            
          // Friends List
          Expanded(
            child: _buildFriendsList(),
          ),
          
          // Create Button
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

        // Filter friends by search query
        final filteredFriends = friendViewModel.friends.where((friend) {
          if (_searchQuery.isEmpty) return true;
          return friend.username.toLowerCase().contains(_searchQuery) ||
                 friend.email.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredFriends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No matching friends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'No friends match "$_searchQuery"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredFriends.length,
          itemBuilder: (context, index) {
            final friend = filteredFriends[index];
            final isSelected = _selectedUserIds.contains(friend.id);
            
            return _buildFriendListItem(friend, isSelected);
          },
        );
      },
    );
  }
  
  Widget _buildFriendListItem(User friend, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: friend.avatar != null
              ? NetworkImage(friend.avatar!)
              : null,
          child: friend.avatar == null
              ? Text(
                  friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18),
                )
              : null,
        ),
        title: Text(
          friend.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(friend.email),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.add_circle_outline, color: Colors.grey),
        onTap: () => _toggleUser(friend.id),
      ),
    );
  }

  Widget _buildSelectedUsersChips() {
    return Consumer<FriendViewModel>(
      builder: (context, friendViewModel, child) {
        final selectedFriends = friendViewModel.friends
            .where((friend) => _selectedUserIds.contains(friend.id))
            .toList();

        if (selectedFriends.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          width: double.infinity,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: selectedFriends.map((friend) => _buildUserChip(friend)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildUserChip(User user) {
    return Chip(
      avatar: CircleAvatar(
        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
        child: user.avatar == null
            ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
            : null,
      ),
      label: Text(user.username),
      deleteIcon: const Icon(Icons.cancel, size: 18),
      onDeleted: () => _toggleUser(user.id),
      backgroundColor: Colors.blue.shade50,
      deleteIconColor: Colors.blue.shade700,
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _selectedUserIds.isEmpty || _isCreatingChat ? null : _createChat,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isCreatingChat
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isGroupChat 
                    ? 'Create Group Chat (${_selectedUserIds.length})' 
                    : 'Start Chat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
} 