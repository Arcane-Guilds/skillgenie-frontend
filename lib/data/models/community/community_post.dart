class CommunityPost {
  final String id;
  final String username;
  final String userAvatar;
  final String title;
  final String content;
  final String timeAgo;
  final int likes;
  final int comments;
  final List<String> tags;
  final bool isSolved;

  CommunityPost({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.isSolved,
  });
} 