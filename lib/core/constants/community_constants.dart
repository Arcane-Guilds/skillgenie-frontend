class CommunityConstants {
  // Base path
  static const String basePath = 'community';

  // Posts endpoints
  static const String posts = '$basePath/posts';
  static const String allPosts = '$posts/all';
  static const String postById = '$posts'; // + /{postId}
  
  // Comments endpoints
  static const String comments = '$basePath/comments';
  static const String commentsWithReplies = '$posts'; // + /{postId}/comments-with-replies
  static const String replyToComment = '$comments'; // + /{commentId}/reply
  
  // Likes endpoints
  static const String likes = '$basePath/likes';

  // Query parameters
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
} 