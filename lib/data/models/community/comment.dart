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
    try {
      // Basic validation to prevent processing empty or invalid JSON
      if (json.isEmpty) {
        print('Warning: Received null or empty JSON for Comment');
        throw ArgumentError('Invalid JSON: null or empty');
      }

      print('Parsing Comment JSON: ${json.toString().substring(0, json.toString().length > 100 ? 100 : json.toString().length)}...');
      
      // Extract required fields
      String id = '';
      if (json.containsKey('_id')) {
        id = json['_id']?.toString() ?? '';
      } else if (json.containsKey('id')) {
        id = json['id']?.toString() ?? '';
      }
      
      // Extract content safely
      String content = json['content']?.toString() ?? '';
      
      // Extract author safely
      UserPreview author;
      if (json.containsKey('author') && json['author'] != null) {
        try {
          if (json['author'] is Map) {
            author = UserPreview.fromJson(json['author']);
          } else if (json['author'] is String) {
            // Handle case where author is just an ID
            author = UserPreview(id: json['author'], username: 'Unknown User');
          } else {
            throw const FormatException('Author is not a Map or String');
          }
        } catch (e) {
          print('Error parsing author: $e');
          author = UserPreview(id: '', username: 'Unknown User');
        }
      } else {
        author = UserPreview(id: '', username: 'Unknown User');
      }
      
      // Extract postId safely
      String postId = '';
      if (json.containsKey('postId')) {
        postId = json['postId']?.toString() ?? '';
      } else if (json.containsKey('post') && json['post'] is String) {
        postId = json['post']?.toString() ?? '';
      } else if (json.containsKey('post') && json['post'] is Map) {
        postId = json['post']['_id']?.toString() ?? '';
      }
      
      // Extract parentCommentId safely
      String? parentCommentId;
      if (json.containsKey('parentComment') && json['parentComment'] != null) {
        if (json['parentComment'] is String) {
          parentCommentId = json['parentComment'];
        } else if (json['parentComment'] is Map && json['parentComment'].containsKey('_id')) {
          parentCommentId = json['parentComment']['_id']?.toString();
        }
      } else if (json.containsKey('parentCommentId') && json['parentCommentId'] != null) {
        parentCommentId = json['parentCommentId']?.toString();
      }
      
      // Extract likeCount safely
      int likeCount = 0;
      if (json.containsKey('likeCount') && json['likeCount'] != null) {
        try {
          if (json['likeCount'] is int) {
            likeCount = json['likeCount'];
          } else {
            likeCount = int.tryParse(json['likeCount'].toString()) ?? 0;
          }
        } catch (e) {
          print('Error parsing likeCount: $e');
        }
      }
      
      // Extract isLiked safely
      bool isLiked = false;
      if (json.containsKey('isLiked') && json['isLiked'] != null) {
        try {
          if (json['isLiked'] is bool) {
            isLiked = json['isLiked'];
          } else {
            isLiked = json['isLiked'].toString().toLowerCase() == 'true';
          }
        } catch (e) {
          print('Error parsing isLiked: $e');
        }
      }
      
      // Extract dates safely
      DateTime createdAt = DateTime.now();
      if (json.containsKey('createdAt') && json['createdAt'] != null) {
        try {
          if (json['createdAt'] is String) {
            createdAt = DateTime.parse(json['createdAt']);
          } else if (json['createdAt'] is DateTime) {
            createdAt = json['createdAt'];
          }
        } catch (e) {
          print('Error parsing createdAt: $e');
        }
      }
      
      DateTime updatedAt = DateTime.now();
      if (json.containsKey('updatedAt') && json['updatedAt'] != null) {
        try {
          if (json['updatedAt'] is String) {
            updatedAt = DateTime.parse(json['updatedAt']);
          } else if (json['updatedAt'] is DateTime) {
            updatedAt = json['updatedAt'];
          }
        } catch (e) {
          print('Error parsing updatedAt: $e');
        }
      }
      
      // Extract replies safely
      List<Comment>? replies;
      if (json.containsKey('replies') && json['replies'] != null && json['replies'] is List) {
        try {
          replies = [];
          for (var replyJson in json['replies']) {
            try {
              if (replyJson != null) {
                replies.add(Comment.fromJson(replyJson));
              }
            } catch (replyError) {
              print('Error parsing individual reply: $replyError');
              // Skip the problematic reply
            }
          }
        } catch (e) {
          print('Error parsing replies list: $e');
          replies = [];
        }
      }
      
      return Comment(
        id: id,
        content: content,
        author: author,
        postId: postId,
        parentCommentId: parentCommentId,
        likeCount: likeCount,
        isLiked: isLiked,
        createdAt: createdAt,
        updatedAt: updatedAt,
        replies: replies,
      );
    } catch (e) {
      print('Error parsing Comment from JSON: $e');
      // Create a minimal valid comment object
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