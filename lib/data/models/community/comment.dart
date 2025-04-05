import 'user_preview.dart';

class Comment {
  final String id;
  final String content;
  final UserPreview author;
  final String postId;
  final String? parentCommentId;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.postId,
    this.parentCommentId,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Debug the JSON payload
    print('Parsing Comment JSON: $json');
    
    try {
      // Safely extract author data
      Map<String, dynamic> authorJson = {};
      
      // Handle different author data types
      if (json['author'] is Map<String, dynamic>) {
        authorJson = json['author'] as Map<String, dynamic>;
      } else if (json['author'] is String) {
        // Sometimes the backend might send an ID as string
        print('Author is a string ID: ${json['author']}');
        authorJson = {'_id': json['author'], 'username': 'Unknown User'};
      } else if (json['author'] == null) {
        print('Author is null, using default');
        authorJson = {'_id': '', 'username': 'Unknown User'};
      } else {
        // Try to convert to map if possible
        try {
          print('Attempting to convert author to Map: ${json['author']}');
          authorJson = Map<String, dynamic>.from(json['author'] as Map);
        } catch (e) {
          print('Error converting author to Map: $e');
          authorJson = {'_id': '', 'username': 'Unknown User'};
        }
      }

      // Parse the dates safely
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      
      try {
        if (json['createdAt'] != null && json['createdAt'].toString().isNotEmpty) {
          createdAt = DateTime.parse(json['createdAt'].toString());
        }
        
        if (json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty) {
          updatedAt = DateTime.parse(json['updatedAt'].toString());
        }
      } catch (e) {
        print('Error parsing dates: $e');
      }
      
      // Parse numeric fields safely
      int likeCount = 0;
      
      if (json['likeCount'] is int) {
        likeCount = json['likeCount'];
      } else if (json['likeCount'] is String) {
        likeCount = int.tryParse(json['likeCount']) ?? 0;
      }
      
      // Parse boolean fields safely
      bool isLiked = false;
      if (json['isLiked'] is bool) {
        isLiked = json['isLiked'];
      } else if (json['isLiked'] is String) {
        isLiked = json['isLiked'].toLowerCase() == 'true';
      } else if (json['isLiked'] is num) {
        isLiked = json['isLiked'] != 0;
      }
      
      // Parse replies safely
      List<Comment>? replies;
      if (json['replies'] is List) {
        try {
          replies = List<Comment>.from(
            (json['replies'] as List).map((x) => Comment.fromJson(x))
          );
        } catch (e) {
          print('Error parsing replies: $e');
          replies = [];
        }
      }
      
      return Comment(
        id: json['_id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        author: UserPreview.fromJson(authorJson),
        postId: json['post']?.toString() ?? '',
        parentCommentId: json['parentComment']?.toString(),
        likeCount: likeCount,
        isLiked: isLiked,
        createdAt: createdAt,
        updatedAt: updatedAt,
        replies: replies,
      );
    } catch (e) {
      print('Error parsing Comment from JSON: $e');
      // Return a default comment in case of error
      return Comment(
        id: '',
        content: 'Error loading comment',
        author: UserPreview(id: '', username: 'Unknown User'),
        postId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'author': author.toJson(),
      'post': postId,
      'parentComment': parentCommentId,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'replies': replies?.map((x) => x.toJson()).toList(),
    };
  }
} 