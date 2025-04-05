import 'user_preview.dart';

class Post {
  final String id;
  final String title;
  final String content;
  final UserPreview author;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    this.title = '',
    required this.content,
    required this.author,
    this.images = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Debug the JSON payload
    print('Parsing Post JSON: $json');
    
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
      
      // Parse images safely
      List<String> images = [];
      if (json['images'] is List) {
        images = List<String>.from(
          (json['images'] as List).map((img) => img.toString())
        );
      }
      
      // Parse numeric fields safely
      int likeCount = 0;
      int commentCount = 0;
      
      if (json['likeCount'] is int) {
        likeCount = json['likeCount'];
      } else if (json['likeCount'] is String) {
        likeCount = int.tryParse(json['likeCount']) ?? 0;
      }
      
      if (json['commentCount'] is int) {
        commentCount = json['commentCount'];
      } else if (json['commentCount'] is String) {
        commentCount = int.tryParse(json['commentCount']) ?? 0;
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
      
      return Post(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        author: UserPreview.fromJson(authorJson),
        images: images,
        likeCount: likeCount,
        commentCount: commentCount,
        isLiked: isLiked,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error parsing Post from JSON: $e');
      // Return a default post in case of error
      return Post(
        id: '',
        title: 'Error',
        content: 'Error loading post content',
        author: UserPreview(id: '', username: 'Unknown User'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'author': author.toJson(),
      'images': images,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Post copyWith({
    String? id,
    String? title,
    String? content,
    UserPreview? author,
    List<String>? images,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      images: images ?? this.images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 