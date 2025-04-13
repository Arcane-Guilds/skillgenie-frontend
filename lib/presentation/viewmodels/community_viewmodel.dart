import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/repositories/community_repository.dart';
import '../../data/models/community/post.dart';
import '../../data/models/community/comment.dart';
import '../../data/models/community/user_preview.dart';
import 'auth/auth_viewmodel.dart';

enum CommunityStatus {
  initial,
  loading,
  loaded,
  error,
}

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _communityRepository;
  final AuthViewModel _authViewModel;
  
  // Timer for auto-retrying post loading
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;
  
  // SharedPreferences keys
  static const String _likedPostsKey = 'liked_posts';
  static const String _likedCommentsKey = 'liked_comments';
  static const String _commentRepliesKey = 'comment_replies';
  
  // Cache of liked post and comment IDs
  Set<String> _likedPostIds = {};
  Set<String> _likedCommentIds = {};
  // Cache of comment replies - map of parent comment ID to list of replies
  Map<String, List<Map<String, dynamic>>> _commentRepliesCache = {};

  CommunityStatus _postsStatus = CommunityStatus.initial;
  CommunityStatus _postDetailStatus = CommunityStatus.initial;
  CommunityStatus _commentsStatus = CommunityStatus.initial;
  CommunityStatus _createPostStatus = CommunityStatus.initial;
  CommunityStatus _createCommentStatus = CommunityStatus.initial;

  List<Post> _posts = [];
  Post? _selectedPost;
  List<Comment> _comments = [];
  int _commentsTotalCount = 0;
  bool _hasMoreComments = false;
  int _currentCommentsPage = 1;
  String? _errorMessage;
  
  // Add new state variables
  List<Post> _userPosts = [];
  CommunityStatus _userPostsStatus = CommunityStatus.initial;
  int _userPostsTotal = 0;

  // Constructor to automatically load posts when created
  CommunityViewModel({
    required CommunityRepository communityRepository,
    required AuthViewModel authViewModel,
  }) : 
    _communityRepository = communityRepository,
    _authViewModel = authViewModel {
    print('CommunityViewModel initialized');
    
    // Load cached like statuses first
    _loadLikedCache();
    
    // Then load cached replies
    _loadRepliesCache();
    
    // Load posts automatically when ViewModel is created
    // Small delay to ensure auth is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      print('Delayed initialization triggered, loading posts');
      loadPosts();
    });
    
    // Listen to auth changes and reload posts when user logs in
    _authViewModel.addListener(_onAuthChanged);
  }
  
  @override
  void dispose() {
    print('CommunityViewModel disposed');
    _retryTimer?.cancel();
    _authViewModel.removeListener(_onAuthChanged);
    super.dispose();
  }
  
  void _onAuthChanged() {
    print('Auth status changed: isAuthenticated=${_authViewModel.isAuthenticated}');
    
    // Reload data when auth status changes (user logs in)
    if (_authViewModel.isAuthenticated) {
      print('User authenticated, reloading data');
      
      // Load cached like statuses
      _loadLikedCache();
      
      // Load cached replies
      _loadRepliesCache();
      
      // Finally load posts data
      loadPosts();
    } else {
      print('User logged out or not authenticated');
    }
  }

  // Load liked posts and comments from SharedPreferences
  Future<void> _loadLikedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authViewModel.user?.id ?? '';
      
      // Only load cache if user is logged in
      if (userId.isNotEmpty) {
        final likedPosts = prefs.getStringList('${_likedPostsKey}_$userId') ?? [];
        final likedComments = prefs.getStringList('${_likedCommentsKey}_$userId') ?? [];
        
        _likedPostIds = likedPosts.toSet();
        _likedCommentIds = likedComments.toSet();
        
        print('Loaded ${_likedPostIds.length} liked posts and ${_likedCommentIds.length} liked comments from cache');
      }
    } catch (e) {
      print('Error loading liked cache: $e');
    }
  }
  
  // Load comment replies from SharedPreferences
  Future<void> _loadRepliesCache() async {
    try {
      print('Starting to load replies cache...');
      final prefs = await SharedPreferences.getInstance();
      final userId = _authViewModel.user?.id ?? '';
      
      // Only load cache if user is logged in
      if (userId.isNotEmpty) {
        print('User ID is available: $userId');
        final repliesJson = prefs.getString('${_commentRepliesKey}_$userId');
        print('Loaded raw replies data: ${repliesJson != null ? 'Data exists (${repliesJson.length} bytes)' : 'No data found'}');
        
        if (repliesJson != null) {
          try {
            final Map<String, dynamic> repliesMap = json.decode(repliesJson);
            
            _commentRepliesCache = {};
            repliesMap.forEach((commentId, repliesList) {
              _commentRepliesCache[commentId] = (repliesList as List)
                  .map((reply) => Map<String, dynamic>.from(reply))
                  .toList();
              print('Loaded ${(repliesList).length} replies for comment $commentId');
            });
            
            int totalReplies = 0;
            _commentRepliesCache.forEach((_, replies) {
              totalReplies += replies.length;
            });
            
            print('Successfully loaded replies for ${_commentRepliesCache.length} comments, total $totalReplies replies from cache');
          } catch (parseError) {
            print('Error parsing replies JSON: $parseError');
            // Attempt to recover by initializing an empty cache
            _commentRepliesCache = {};
          }
        } else {
          print('No replies cache found for user $userId');
          _commentRepliesCache = {};
        }
      } else {
        print('No user ID available, skipping replies cache loading');
      }
    } catch (e) {
      print('Error loading replies cache: $e');
      _commentRepliesCache = {};
    }
  }
  
  // Save liked posts and comments to SharedPreferences
  Future<void> _saveLikedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authViewModel.user?.id ?? '';
      
      // Only save cache if user is logged in
      if (userId.isNotEmpty) {
        await prefs.setStringList('${_likedPostsKey}_$userId', _likedPostIds.toList());
        await prefs.setStringList('${_likedCommentsKey}_$userId', _likedCommentIds.toList());
        
        print('Saved ${_likedPostIds.length} liked posts and ${_likedCommentIds.length} liked comments to cache');
      }
    } catch (e) {
      print('Error saving liked cache: $e');
    }
  }
  
  // Save comment replies to SharedPreferences
  
  // Update comment replies cache for a specific comment
  
  // Update cached like status for a post
  void _updatePostLikeCache(String postId, bool isLiked) {
    if (isLiked) {
      _likedPostIds.add(postId);
    } else {
      _likedPostIds.remove(postId);
    }
    _saveLikedCache();
  }
  
  // Update cached like status for a comment
  void _updateCommentLikeCache(String commentId, bool isLiked) {
    if (isLiked) {
      _likedCommentIds.add(commentId);
    } else {
      _likedCommentIds.remove(commentId);
    }
    _saveLikedCache();
  }

  // Getters
  CommunityStatus get postsStatus => _postsStatus;
  CommunityStatus get postDetailStatus => _postDetailStatus;
  CommunityStatus get commentsStatus => _commentsStatus;
  CommunityStatus get createPostStatus => _createPostStatus;
  CommunityStatus get createCommentStatus => _createCommentStatus;
  
  List<Post> get posts => _posts;
  Post? get selectedPost => _selectedPost;
  List<Comment> get comments => _comments;
  int get commentsTotalCount => _commentsTotalCount;
  bool get hasMoreComments => _hasMoreComments;
  int get currentCommentsPage => _currentCommentsPage;
  String? get errorMessage => _errorMessage;

  // Add getters
  List<Post> get userPosts => _userPosts;
  CommunityStatus get userPostsStatus => _userPostsStatus;
  int get userPostsTotal => _userPostsTotal;

  // Load all posts
  Future<void> loadPosts() async {
    // Cancel any existing retry timer
    _retryTimer?.cancel();
    
    if (_postsStatus == CommunityStatus.loading) return;

    _postsStatus = CommunityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _postsStatus = CommunityStatus.error;
        notifyListeners();
        
        // Auto-retry if not authenticated (auth might not be ready yet)
        _scheduleRetry();
        return;
      }

      // Store the like status of current posts to preserve them
      Map<String, bool> likeStatusMap = {};
      for (var post in _posts) {
        likeStatusMap[post.id] = post.isLiked;
      }

      final result = await _communityRepository.getAllPosts(token);
      
      // Debug the API response structure
      print('API Response: $result');
      
      // Safely extract posts data with null checking
      if (result.containsKey('posts') && result['posts'] is List) {
        final List<dynamic> postsData = result['posts'];
        
        try {
          _posts = postsData.map((postData) {
            Post post = Post.fromJson(postData);
            
            // Apply cached like status first
            bool cachedLikeStatus = _likedPostIds.contains(post.id);
            
            // Preserve like status if we already know it from the current session
            if (likeStatusMap.containsKey(post.id)) {
              post = post.copyWith(isLiked: likeStatusMap[post.id]);
            } 
            // Otherwise use the cached like status
            else if (cachedLikeStatus) {
              post = post.copyWith(isLiked: true);
            }
            
            return post;
          }).toList();
          
          // Reset retry count on success
          _retryCount = 0;
        } catch (parseError) {
          print('Error parsing post data: $parseError');
          // If parsing individual posts fails, we still want to show any that succeeded
          _posts = [];
          for (var postData in postsData) {
            try {
              final post = Post.fromJson(postData);
              
              // Apply cached like status first
              bool cachedLikeStatus = _likedPostIds.contains(post.id);
              
              // Preserve like status if we already know it from the current session
              if (likeStatusMap.containsKey(post.id)) {
                _posts.add(post.copyWith(isLiked: likeStatusMap[post.id]));
              } 
              // Otherwise use the cached like status
              else if (cachedLikeStatus) {
                _posts.add(post.copyWith(isLiked: true));
              }
              else {
                _posts.add(post);
              }
            } catch (e) {
              print('Skipping invalid post: $e');
            }
          }
        }
      } else {
        // If the API response doesn't match expected format, handle it gracefully
        _posts = [];
        print('Unexpected API response format: $result');
      }
      
      _postsStatus = CommunityStatus.loaded;
    } catch (e) {
      print('Error loading posts: $e');
      _errorMessage = e.toString();
      _postsStatus = CommunityStatus.error;
      
      // Schedule a retry
      _scheduleRetry();
    }
    
    notifyListeners();
  }
  
  // Schedule an automatic retry after an error
  void _scheduleRetry() {
    if (_retryCount < maxRetries) {
      _retryCount++;
      final delay = Duration(seconds: _retryCount * 2); // Exponential backoff
      print('Scheduling retry #$_retryCount in ${delay.inSeconds} seconds');
      
      _retryTimer = Timer(delay, () {
        print('Auto-retrying loadPosts()');
        loadPosts();
      });
    }
  }

  // Load post details
  Future<void> loadPostById(String postId) async {
    _postDetailStatus = CommunityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _postDetailStatus = CommunityStatus.error;
        notifyListeners();
        return;
      }

      _selectedPost = await _communityRepository.getPostById(token, postId);
      _postDetailStatus = CommunityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _postDetailStatus = CommunityStatus.error;
    }
    
    notifyListeners();
  }

  // Load comments for a post
  Future<void> loadComments(String postId, {bool loadMore = false}) async {
    if (_commentsStatus == CommunityStatus.loading) return;
    
    if (!loadMore) {
      _commentsStatus = CommunityStatus.loading;
      _currentCommentsPage = 1;
    }
    
    notifyListeners();
    
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _commentsStatus = CommunityStatus.error;
        notifyListeners();
        return;
      }

      final result = await _communityRepository.getCommentsForPost(
        token,
        postId,
        page: _currentCommentsPage,
        limit: 20,
      );
      
      print('Loaded comments result: $result');
      
      try {
        // First, parse all comments from the API into a flat list
        final List<dynamic> commentsJson = result['comments'];
        List<Comment> allComments = commentsJson.map<Comment>((item) => Comment.fromJson(item)).toList();
        
        // Separate top-level comments and replies
        List<Comment> topLevelComments = [];
        Map<String, List<Comment>> repliesByParentId = {};
        
        for (Comment comment in allComments) {
          // Check if this is a top-level comment or a reply
          if (comment.parentCommentId == null || comment.parentCommentId!.isEmpty) {
            topLevelComments.add(comment);
          } else {
            // This is a reply - add it to the correct parent
            String parentId = comment.parentCommentId!;
            if (!repliesByParentId.containsKey(parentId)) {
              repliesByParentId[parentId] = [];
            }
            repliesByParentId[parentId]!.add(comment);
          }
        }
        
        // Now attach replies to their parent comments
        List<Comment> organizedComments = topLevelComments.map((comment) {
          if (repliesByParentId.containsKey(comment.id)) {
            // Create a new comment with the replies attached
            return Comment(
              id: comment.id,
              content: comment.content,
              author: comment.author,
              postId: comment.postId,
              parentCommentId: comment.parentCommentId,
              likeCount: comment.likeCount,
              isLiked: comment.isLiked,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              replies: repliesByParentId[comment.id],
            );
          } else {
            // No replies for this comment
            return comment;
          }
        }).toList();
        
        // Replace all comments with our organized structure
        _comments = organizedComments;
        
        // Update counts for UI
        _commentsTotalCount = topLevelComments.length;
        _hasMoreComments = result['hasMore'] ?? false;
        _commentsStatus = CommunityStatus.loaded;
        
        // Debug info
        int totalReplies = 0;
        for (var comment in _comments) {
          if (comment.replies != null) {
            totalReplies += comment.replies!.length;
          }
        }
        print('Loaded ${_comments.length} top-level comments with $totalReplies replies total');
      } catch (e) {
        print('Error parsing comments: $e');
        _errorMessage = 'Failed to parse comments: $e';
        _commentsStatus = CommunityStatus.error;
        notifyListeners();
        return;
      }
    } catch (e) {
      print('Error loading comments: $e');
      _errorMessage = e.toString();
      _commentsStatus = CommunityStatus.error;
    }
    
    notifyListeners();
  }

  // Create a new post
  Future<Post?> createPost(String content, List<String> images) async {
    _createPostStatus = CommunityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _createPostStatus = CommunityStatus.error;
        notifyListeners();
        return null;
      }

      // Extract title from first paragraph of content
      final lines = content.split('\n');
      String title = lines[0];
      
      // Ensure content is at least the title if user didn't add more
      String postContent = content;
      
      print('Creating post with title: $title, content: $postContent');

      final newPost = await _communityRepository.createPost(token, postContent, images);
      
      // Add the new post to the beginning of the list
      _posts.insert(0, newPost);
      _createPostStatus = CommunityStatus.loaded;
      
      notifyListeners();
      return newPost;
    } catch (e) {
      print('Error in createPost: $e');
      _errorMessage = e.toString();
      _createPostStatus = CommunityStatus.error;
      notifyListeners();
      return null;
    }
  }

  // Create a comment on a post
  Future<Comment?> createComment(String postId, String content, {String? parentCommentId}) async {
    _createCommentStatus = CommunityStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _createCommentStatus = CommunityStatus.error;
        notifyListeners();
        return null;
      }

      final newComment = await _communityRepository.createComment(
        token, 
        postId, 
        content,
        parentCommentId: parentCommentId,
      );
      
      // Update the post comment count if we have it in our list
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex >= 0) {
        final updatedPost = _posts[postIndex].copyWith(
          commentCount: _posts[postIndex].commentCount + 1
        );
        _posts[postIndex] = updatedPost;
      }
      
      // Update the selected post if it's the same post
      if (_selectedPost?.id == postId) {
        _selectedPost = _selectedPost!.copyWith(
          commentCount: _selectedPost!.commentCount + 1
        );
      }
      
      _createCommentStatus = CommunityStatus.loaded;
      
      // Handle top-level comments vs replies differently
      if (parentCommentId == null) {
        // This is a top-level comment - add it to the beginning of our comments list
        _comments.insert(0, newComment);
        _commentsTotalCount++;
      } else {
        // This is a reply - find the parent comment and add this as a reply
        final parentIndex = _comments.indexWhere((c) => c.id == parentCommentId);
        if (parentIndex >= 0) {
          final parentComment = _comments[parentIndex];
          
          // Create a list of updated replies, ensuring proper parentCommentId values
          final List<Comment> updatedReplies = [
            ...(parentComment.replies ?? []),
            // Ensure the reply has the correct parentCommentId set
            Comment(
              id: newComment.id,
              content: newComment.content,
              author: newComment.author,
              postId: newComment.postId,
              parentCommentId: parentCommentId, // Explicitly set the parent ID
              likeCount: newComment.likeCount,
              isLiked: newComment.isLiked,
              createdAt: newComment.createdAt,
              updatedAt: newComment.updatedAt,
            )
          ];
          
          // Create an updated parent comment with these replies
          final updatedParentComment = Comment(
            id: parentComment.id,
            content: parentComment.content,
            author: parentComment.author,
            postId: parentComment.postId,
            parentCommentId: parentComment.parentCommentId,
            likeCount: parentComment.likeCount,
            isLiked: parentComment.isLiked,
            createdAt: parentComment.createdAt,
            updatedAt: parentComment.updatedAt,
            replies: updatedReplies,
          );
          
          _comments[parentIndex] = updatedParentComment;
        } else {
          print('Warning: Could not find parent comment with ID $parentCommentId to attach reply');
          // If we can't find the parent comment, add the reply as a standalone comment for now
          // It will be reorganized next time comments are loaded
          _comments.insert(0, newComment);
        }
      }
      
      notifyListeners();
      return newComment;
    } catch (e) {
      print('Error creating comment: $e');
      _errorMessage = e.toString();
      _createCommentStatus = CommunityStatus.error;
      notifyListeners();
      return null;
    }
  }

  // Toggle like on a post
  Future<void> togglePostLike(String postId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      // Find the post in both lists
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      final userPostIndex = _userPosts.indexWhere((p) => p.id == postId);
      final isCurrentlyLiked = postIndex >= 0 ? _posts[postIndex].isLiked : 
                              userPostIndex >= 0 ? _userPosts[userPostIndex].isLiked : false;
      
      // Optimistically update the UI in both lists
      if (postIndex >= 0) {
        final currentLikeCount = _posts[postIndex].likeCount;
        final updatedPost = _posts[postIndex].copyWith(
          isLiked: !isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1
        );
        _posts[postIndex] = updatedPost;
      }

      // Update in user posts list if it exists there
      if (userPostIndex >= 0) {
        final currentLikeCount = _userPosts[userPostIndex].likeCount;
        final updatedPost = _userPosts[userPostIndex].copyWith(
          isLiked: !isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1
        );
        _userPosts[userPostIndex] = updatedPost;
      }
      
      // Also update the selected post if it's the same post
      if (_selectedPost?.id == postId) {
        final currentLikeCount = _selectedPost!.likeCount;
        _selectedPost = _selectedPost!.copyWith(
          isLiked: !isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1
        );
      }
      
      // Update the cached like status
      _updatePostLikeCache(postId, !isCurrentlyLiked);
      
      notifyListeners();
      
      // Call the API
      Map<String, dynamic> result;
      if (isCurrentlyLiked) {
        result = await _communityRepository.unlikePost(token, postId);
      } else {
        result = await _communityRepository.likePost(token, postId);
      }
      
      // Update both lists with the server-confirmed like status
      if (result.containsKey('isLiked')) {
        bool serverLikeStatus = result['isLiked'];
        
        // Update the cached like status with server response
        _updatePostLikeCache(postId, serverLikeStatus);
        
        // If server response differs from our optimistic update, correct it in both lists
        if (postIndex >= 0 && _posts[postIndex].isLiked != serverLikeStatus) {
          final currentLikeCount = _posts[postIndex].likeCount;
          final updatedPost = _posts[postIndex].copyWith(
            isLiked: serverLikeStatus,
            likeCount: serverLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
          _posts[postIndex] = updatedPost;
        }

        if (userPostIndex >= 0 && _userPosts[userPostIndex].isLiked != serverLikeStatus) {
          final currentLikeCount = _userPosts[userPostIndex].likeCount;
          final updatedPost = _userPosts[userPostIndex].copyWith(
            isLiked: serverLikeStatus,
            likeCount: serverLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
          _userPosts[userPostIndex] = updatedPost;
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error toggling post like: $e');
      
      // Revert the optimistic update in case of error in both lists
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      final userPostIndex = _userPosts.indexWhere((p) => p.id == postId);
      
      // Determine the current like status from either list
      bool? currentLikeStatus;
      if (postIndex >= 0) {
        currentLikeStatus = _posts[postIndex].isLiked;
      } else if (userPostIndex >= 0) {
        currentLikeStatus = _userPosts[userPostIndex].isLiked;
      }
      
      if (currentLikeStatus != null) {
        if (postIndex >= 0) {
          final currentLikeCount = _posts[postIndex].likeCount;
          final updatedPost = _posts[postIndex].copyWith(
            isLiked: !currentLikeStatus,
            likeCount: !currentLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
          _posts[postIndex] = updatedPost;
        }

        if (userPostIndex >= 0) {
          final currentLikeCount = _userPosts[userPostIndex].likeCount;
          final updatedPost = _userPosts[userPostIndex].copyWith(
            isLiked: !currentLikeStatus,
            likeCount: !currentLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
          _userPosts[userPostIndex] = updatedPost;
        }
        
        if (_selectedPost?.id == postId) {
          final currentLikeCount = _selectedPost!.likeCount;
          _selectedPost = _selectedPost!.copyWith(
            isLiked: !currentLikeStatus,
            likeCount: !currentLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
        }
        
        // Revert the cache update
        _updatePostLikeCache(postId, !currentLikeStatus);
      }
      
      _errorMessage = 'Failed to update like status. Please try again.';
      notifyListeners();
    }
  }

  // Toggle like on a comment
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      // Find the comment in our list
      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      
      if (commentIndex >= 0) {
        final isCurrentlyLiked = _comments[commentIndex].isLiked;
        final currentLikeCount = _comments[commentIndex].likeCount;
        
        // Optimistically update the UI
        final updatedComment = Comment(
          id: _comments[commentIndex].id,
          content: _comments[commentIndex].content,
          author: _comments[commentIndex].author,
          postId: _comments[commentIndex].postId,
          parentCommentId: _comments[commentIndex].parentCommentId,
          likeCount: isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1,
          isLiked: !isCurrentlyLiked,
          createdAt: _comments[commentIndex].createdAt,
          updatedAt: _comments[commentIndex].updatedAt,
          replies: _comments[commentIndex].replies,
        );
        
        _comments[commentIndex] = updatedComment;
        
        // Update the cached like status
        _updateCommentLikeCache(commentId, !isCurrentlyLiked);
        
        notifyListeners();
      
        // Call the API
        Map<String, dynamic> result;
        if (isCurrentlyLiked) {
          result = await _communityRepository.unlikeComment(token, commentId);
        } else {
          result = await _communityRepository.likeComment(token, commentId);
        }
        
        // Update the comment with the server-confirmed like status
        if (result.containsKey('isLiked')) {
          bool serverLikeStatus = result['isLiked'];
          
          // Update the cached like status with server response
          _updateCommentLikeCache(commentId, serverLikeStatus);
          
          // If server response differs from our optimistic update, correct it
          final newCommentIndex = _comments.indexWhere((c) => c.id == commentId);
          if (newCommentIndex >= 0 && _comments[newCommentIndex].isLiked != serverLikeStatus) {
            final comment = _comments[newCommentIndex];
            final currentLikeCount = comment.likeCount;
            
            final correctedComment = Comment(
              id: comment.id,
              content: comment.content,
              author: comment.author,
              postId: comment.postId,
              parentCommentId: comment.parentCommentId,
              likeCount: serverLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1,
              isLiked: serverLikeStatus,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              replies: comment.replies,
            );
            
            _comments[newCommentIndex] = correctedComment;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error toggling comment like: $e');
      
      // Find the comment to revert the change
      final commentIndex = _comments.indexWhere((c) => c.id == commentId);
      if (commentIndex >= 0) {
        final comment = _comments[commentIndex];
        final isCurrentlyLiked = !comment.isLiked; // It was toggled already
        final currentLikeCount = comment.likeCount;
        
        // Revert the optimistic update
        final revertedComment = Comment(
          id: comment.id,
          content: comment.content,
          author: comment.author,
          postId: comment.postId,
          parentCommentId: comment.parentCommentId,
          likeCount: isCurrentlyLiked ? currentLikeCount + 1 : currentLikeCount - 1,
          isLiked: isCurrentlyLiked,
          createdAt: comment.createdAt,
          updatedAt: comment.updatedAt,
          replies: comment.replies,
        );
        
        _comments[commentIndex] = revertedComment;
        
        // Revert the cache update
        _updateCommentLikeCache(commentId, isCurrentlyLiked);
      }
      
      _errorMessage = 'Failed to update like status. Please try again.';
      notifyListeners();
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      await _communityRepository.deletePost(token, postId);
      
      // Remove the post from our list
      _posts.removeWhere((p) => p.id == postId);
      
      // Clear selected post if it was the deleted one
      if (_selectedPost?.id == postId) {
        _selectedPost = null;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      await _communityRepository.deleteComment(token, commentId);
      
      // Find the comment to get its post ID
      final comment = _comments.firstWhere(
        (c) => c.id == commentId, 
        orElse: () => Comment(
          id: '',
          content: '',
          author: UserPreview(id: '', username: ''),
          postId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Only proceed if we found a valid comment
      if (comment.id.isNotEmpty) {
        final String postId = comment.postId;
        
        // Remove the comment from our list
        _comments.removeWhere((c) => c.id == commentId);
        
        // Update the post comment count if we have it in our list
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex >= 0) {
          final updatedPost = _posts[postIndex].copyWith(
            commentCount: _posts[postIndex].commentCount - 1
          );
          _posts[postIndex] = updatedPost;
        }
        
        // Update the selected post if it's the same post
        if (_selectedPost?.id == postId) {
          _selectedPost = _selectedPost!.copyWith(
            commentCount: _selectedPost!.commentCount - 1
          );
        }
            
        _commentsTotalCount--;
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting comment: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Reset error message
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to merge replies from different sources

  // Toggle like on a comment reply
  Future<void> toggleReplyLike(String replyId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      // Find the reply in our comments list
      bool replyFound = false;
      bool isCurrentlyLiked = false;
      
      // Look through all comments and their replies
      for (var comment in _comments) {
        if (comment.replies != null) {
          for (var i = 0; i < comment.replies!.length; i++) {
            if (comment.replies![i].id == replyId) {
              replyFound = true;
              isCurrentlyLiked = comment.replies![i].isLiked;
              
              // Optimistically update the UI before API call completes
              final updatedReplies = List<Comment>.from(comment.replies!);
              updatedReplies[i] = Comment(
                id: comment.replies![i].id,
                content: comment.replies![i].content,
                author: comment.replies![i].author,
                postId: comment.replies![i].postId,
                parentCommentId: comment.replies![i].parentCommentId,
                likeCount: comment.replies![i].likeCount + (isCurrentlyLiked ? -1 : 1),
                isLiked: !isCurrentlyLiked,
                createdAt: comment.replies![i].createdAt,
                updatedAt: comment.replies![i].updatedAt,
              );
              
              // Update the comment with new replies
              final int commentIndex = _comments.indexOf(comment);
              if (commentIndex >= 0) {
                _comments[commentIndex] = Comment(
                  id: comment.id,
                  content: comment.content,
                  author: comment.author,
                  postId: comment.postId,
                  parentCommentId: comment.parentCommentId,
                  likeCount: comment.likeCount,
                  isLiked: comment.isLiked,
                  createdAt: comment.createdAt,
                  updatedAt: comment.updatedAt,
                  replies: updatedReplies,
                );
              }
              
              break;
            }
          }
        }
        if (replyFound) break;
      }
      
      if (!replyFound) {
        print('Reply $replyId not found in current comments list');
        return;
      }
      
      notifyListeners();
      
      try {
        // Call the appropriate API endpoint based on the current like status
        if (isCurrentlyLiked) {
          await _communityRepository.unlikeReply(token, replyId);
          _likedCommentIds.remove(replyId);
        } else {
          await _communityRepository.likeReply(token, replyId);
          _likedCommentIds.add(replyId);
        }
        
        // Save updated like status to cache
        _saveLikedCache();
      } catch (e) {
        print('API error toggling reply like: $e');
        // On error, revert the optimistic update
        // We should reload the comments to get the correct state
        loadComments(_selectedPost!.id);
      }
    } catch (e) {
      print('Error in toggleReplyLike: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

 Future<void> loadUserPosts(String userId) async {
  _userPostsStatus = CommunityStatus.loading;
  _errorMessage = null;
  notifyListeners();

  try {
    final token = _authViewModel.tokens?.accessToken;
    if (token == null) {
      _errorMessage = 'Not authenticated';
      _userPostsStatus = CommunityStatus.error;
      notifyListeners();
      return;
    }

    final result = await _communityRepository.getUserPosts(token, userId);
    
    if (result.containsKey('posts') && result['posts'] is List) {
      final List<dynamic> postsData = result['posts'];
      
      // Store the like status of current posts to preserve them
      Map<String, bool> likeStatusMap = {};
      for (var post in _userPosts) {
        likeStatusMap[post.id] = post.isLiked;
      }

      _userPosts = postsData.map((postData) {
        Post post = Post.fromJson(postData);
        
        // Apply cached like status first
        bool cachedLikeStatus = _likedPostIds.contains(post.id);
        
        // Preserve like status if we already know it from the current session
        if (likeStatusMap.containsKey(post.id)) {
          post = post.copyWith(isLiked: likeStatusMap[post.id]);
        } 
        // Otherwise use the cached like status
        else if (cachedLikeStatus) {
          post = post.copyWith(isLiked: true);
        }
        
        return post;
      }).toList();

      _userPostsStatus = CommunityStatus.loaded;
    } else {
      _userPosts = [];
      _userPostsStatus = CommunityStatus.error;
      _errorMessage = 'Invalid response format';
    }
  } catch (e) {
    _errorMessage = e.toString();
    _userPostsStatus = CommunityStatus.error;
  }
  
  notifyListeners();
}

  // Update a post
  Future<void> updatePost(String postId, String content, String title) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) {
        _errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }

      // Find the post in our list
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex < 0) {
        _errorMessage = 'Post not found';
        notifyListeners();
        return;
      }

      // Call the API to update the post
      final updatedPost = await _communityRepository.updatePost(
        token,
        postId,
        content,
        title,
      );

      // Update the post in our list
      _posts[postIndex] = updatedPost;

      // Also update the selected post if it's the same post
      if (_selectedPost?.id == postId) {
        _selectedPost = updatedPost;
      }

      // Update in user posts if it exists there
      final userPostIndex = _userPosts.indexWhere((p) => p.id == postId);
      if (userPostIndex >= 0) {
        _userPosts[userPostIndex] = updatedPost;
      }

      notifyListeners();
    } catch (e) {
      print('Error updating post: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
} 