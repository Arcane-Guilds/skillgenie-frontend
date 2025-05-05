import '../models/user_model.dart';

class Chat {
  final String id;
  final List<User> participants;
  final String? name;
  final bool isGroupChat;
  final String? admin; // Store admin ID
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

  Chat copyWith({
    String? id,
    List<User>? participants,
    String? name,
    bool? isGroupChat,
    String? admin,
    DateTime? lastActivity,
    Message? lastMessage,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      name: name ?? this.name,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      admin: admin ?? this.admin,
      lastActivity: lastActivity ?? this.lastActivity,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Handle potential null or non-list participants
    List<User> parsedParticipants = [];
    if (json['participants'] is List) {
      parsedParticipants = (json['participants'] as List<dynamic>)
          .map((participant) {
        // Ensure participant data is a map before parsing
        if (participant is Map<String, dynamic>) {
          return User.fromJson(participant);
        }
        return User(id: participant.toString(), username: 'Unknown User', email: ''); // Placeholder
      })
          .toList();
    }

    // Handle potential null or non-map admin
    String? parsedAdminId;
    if (json['admin'] is Map<String, dynamic>) {
      parsedAdminId = User.fromJson(json['admin']).id;
    } else if (json['admin'] is String) {
      // If admin is just an ID string
      parsedAdminId = json['admin'];
    }

    return Chat(
      id: json['_id'] ?? 'unknown_chat_${DateTime.now().millisecondsSinceEpoch}', // Provide a fallback ID
      participants: parsedParticipants,
      name: json['name'] as String?,
      isGroupChat: json['isGroupChat'] as bool? ?? false,
      admin: parsedAdminId,
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity']) ?? DateTime.now() // Fallback for invalid date
          : DateTime.now(), // Fallback if null
      lastMessage: json['lastMessage'] != null && json['lastMessage'] is Map<String, dynamic>
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  // Add toJson method
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((p) => p.toJson()).toList(), // Convert users to JSON
      'name': name,
      'isGroupChat': isGroupChat,
      'admin': admin, // Admin ID is already a string
      'lastActivity': lastActivity.toIso8601String(), // Convert DateTime to ISO string
      'lastMessage': lastMessage?.toJson(), // Convert message to JSON if not null
      'unreadCount': unreadCount,
    };
  }

  // Get a display name for the chat
  String getDisplayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    if (isGroupChat) {
      // Limit the number of names shown for groups
      final displayNames = participants.map((p) => p.username).take(3).join(', ');
      return participants.length > 3 ? '$displayNames...' : displayNames;
    }

    // For one-on-one chats, display the other person's name
    final otherParticipants = participants.where((p) => p.id != currentUserId).toList();
    if (otherParticipants.isNotEmpty) {
      return otherParticipants.first.username;
    }

    // Fallback if something is wrong (e.g., chat with only self)
    return participants.isNotEmpty ? participants.first.username : 'Chat';
  }

  // Get chat avatar based on participants (for direct messages)
  String? getDisplayAvatar(String currentUserId) {
    if (isGroupChat) {
      // TODO: Return group chat avatar or default
      return null; // Placeholder for group avatar
    }

    // For direct messages, show the other participant's avatar
    final otherParticipant = participants.firstWhere(
          (participant) => participant.id != currentUserId,
      // Provide a fallback in case the list doesn't contain the other user (shouldn't happen in 1-on-1)
      orElse: () => participants.isNotEmpty ? participants.first : User(id: '', username: '', email: ''),
    );

    return otherParticipant.avatar;
  }
}

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String content;
  final List<String> readBy; // List of user IDs who have read the message
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

  Message copyWith({
    String? id,
    String? chatId,
    User? sender,
    String? content,
    List<String>? readBy,
    bool? isSystemMessage,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      readBy: readBy ?? this.readBy,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle potential null or non-map sender
    User parsedSender;
    if (json['sender'] is Map<String, dynamic>) {
      parsedSender = User.fromJson(json['sender']);
    } else {
      parsedSender = User(id: 'unknown_sender', username: 'System', email: ''); // Placeholder for system/unknown
    }

    // Handle potential null or non-list readBy
    List<String> parsedReadBy = [];
    if (json['readBy'] is List) {
      parsedReadBy = (json['readBy'] as List<dynamic>)
          .map((userId) => userId.toString()) // Ensure IDs are strings
          .toList();
    }

    return Message(
      id: json['_id'] ?? 'unknown_msg_${DateTime.now().millisecondsSinceEpoch}', // Fallback ID
      chatId: json['chatId'] ?? 'unknown_chat', // Fallback chatId
      sender: parsedSender,
      content: json['content'] ?? '', // Fallback content
      readBy: parsedReadBy,
      isSystemMessage: json['isSystemMessage'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() // Fallback for invalid date
          : DateTime.now(), // Fallback if null
    );
  }

  // Add toJson method
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'sender': sender.toJson(), // Convert sender User to JSON
      'content': content,
      'readBy': readBy, // List of strings is already JSON-compatible
      'isSystemMessage': isSystemMessage,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to ISO string
    };
  }
}