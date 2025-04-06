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
    try {
      print('Parsing Post JSON: ${json.toString().substring(0, json.toString().length > 100 ? 100 : json.toString().length)}...');
      
      // Extract ID safely
      String id = '';
      if (json.containsKey('_id')) {
        id = json['_id']?.toString() ?? '';
      } else if (json.containsKey('id')) {
        id = json['id']?.toString() ?? '';
      }
      
      // Extract title and content safely
      String title = json['title']?.toString() ?? '';
      String content = json['content']?.toString() ?? '';
      
      // Extract author safely
      UserPreview author;
      if (json.containsKey('author') && json['author'] != null) {
        try {
          author = UserPreview.fromJson(json['author']);
        } catch (e) {
          print('Error parsing post author: $e');
          author = UserPreview(id: '', username: 'Unknown User');
        }
      } else {
        author = UserPreview(id: '', username: 'Unknown User');
      }
      
      // Extract images safely
      List<String> images = [];
      if (json.containsKey('images') && json['images'] != null && json['images'] is List) {
        try {
          images = List<String>.from(json['images'].map((x) => x.toString()));
        } catch (e) {
          print('Error parsing post images: $e');
        }
      }
      
      // Extract numeric counts safely
      int likeCount = 0;
      if (json.containsKey('likeCount') && json['likeCount'] != null) {
        try {
          if (json['likeCount'] is int) {
            likeCount = json['likeCount'];
          } else {
            likeCount = int.parse(json['likeCount'].toString());
          }
        } catch (e) {
          print('Error parsing post likeCount: $e');
        }
      }
      
      int commentCount = 0;
      if (json.containsKey('commentCount') && json['commentCount'] != null) {
        try {
          if (json['commentCount'] is int) {
            commentCount = json['commentCount'];
          } else {
            commentCount = int.parse(json['commentCount'].toString());
          }
        } catch (e) {
          print('Error parsing post commentCount: $e');
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
          print('Error parsing post isLiked: $e');
        }
      }
      
      // Extract dates safely
      DateTime createdAt = DateTime.now();
      if (json.containsKey('createdAt') && json['createdAt'] != null) {
        try {
          createdAt = DateTime.parse(json['createdAt'].toString());
        } catch (e) {
          print('Error parsing post createdAt: $e');
        }
      }
      
      DateTime updatedAt = DateTime.now();
      if (json.containsKey('updatedAt') && json['updatedAt'] != null) {
        try {
          updatedAt = DateTime.parse(json['updatedAt'].toString());
        } catch (e) {
          print('Error parsing post updatedAt: $e');
        }
      }
      
      return Post(
        id: id,
        title: title,
        content: content,
        author: author,
        images: images,
        likeCount: likeCount,
        commentCount: commentCount,
        isLiked: isLiked,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error parsing Post from JSON: $e');
      return Post(
        id: '',
        title: 'Error loading post',
        content: 'There was an error loading this post.',
        author: UserPreview(id: '', username: 'Unknown User'),
        images: [],
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
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