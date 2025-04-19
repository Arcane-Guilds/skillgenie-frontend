import 'dart:convert';
import '../models/user_model.dart';

class Chat {
  final String id;
  final List<User> participants;
  final String? name;
  final bool isGroupChat;
  final String? admin;
  final DateTime lastActivity;
  final Message? lastMessage;
  final int unreadCount;

  Chat({
    required this.id,
    required this.participants,
    this.name,
    required this.isGroupChat,
    this.admin,
    required this.lastActivity,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      participants: (json['participants'] as List<dynamic>)
          .map((participant) => User.fromJson(participant))
          .toList(),
      name: json['name'],
      isGroupChat: json['isGroupChat'] ?? false,
      admin: json['admin'] != null ? User.fromJson(json['admin']).id : null,
      lastActivity: DateTime.parse(json['lastActivity']),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  // Get a display name for the chat
  String getDisplayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    if (isGroupChat) {
      return participants.map((p) => p.username).join(', ');
    }

    // For one-on-one chats, display the other person's name
    final otherParticipants = participants.where((p) => p.id != currentUserId).toList();
    if (otherParticipants.isNotEmpty) {
      return otherParticipants.first.username;
    }

    return 'Chat';
  }

  // Get chat avatar based on participants (for direct messages)
  String? getDisplayAvatar(String currentUserId) {
    if (isGroupChat) {
      // TODO: Return group chat avatar or default
      return null;
    }

    // For direct messages, show the other participant's avatar
    final otherParticipant = participants.firstWhere(
      (participant) => participant.id != currentUserId,
      orElse: () => participants.first,
    );

    return otherParticipant.avatar;
  }
}

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String content;
  final List<String> readBy;
  final bool isSystemMessage;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    required this.readBy,
    required this.isSystemMessage,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      chatId: json['chatId'],
      sender: User.fromJson(json['sender']),
      content: json['content'],
      readBy: (json['readBy'] as List<dynamic>)
          .map((userId) => userId.toString())
          .toList(),
      isSystemMessage: json['isSystemMessage'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 