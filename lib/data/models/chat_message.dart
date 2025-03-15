/// Model class for storing chat messages
class ChatMessage {
  final bool isPrompt;
  final String message;
  final DateTime time;
  final String? imagePath;

  ChatMessage({
    required this.isPrompt,
    required this.message,
    required this.time,
    this.imagePath,
  });

  /// Create a copy of this ChatMessage with modified fields
  ChatMessage copyWith({
    bool? isPrompt,
    String? message,
    DateTime? time,
    String? imagePath,
  }) {
    return ChatMessage(
      isPrompt: isPrompt ?? this.isPrompt,
      message: message ?? this.message,
      time: time ?? this.time,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Convert ChatMessage to a Map
  Map<String, dynamic> toJson() {
    return {
      'isPrompt': isPrompt,
      'message': message,
      'time': time.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  /// Create a ChatMessage from a Map
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      isPrompt: json['isPrompt'] as bool,
      message: json['message'] as String,
      time: DateTime.parse(json['time'] as String),
      imagePath: json['imagePath'] as String?,
    );
  }
} 