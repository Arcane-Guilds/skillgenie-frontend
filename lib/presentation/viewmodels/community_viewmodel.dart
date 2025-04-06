import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/services/service_locator.dart';
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
              print('Loaded ${(repliesList as List).length} replies for comment $commentId');
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
  Future<void> _saveRepliesCache() async {
    try {
      print('Starting to save replies cache...');
      final prefs = await SharedPreferences.getInstance();
      final userId = _authViewModel.user?.id ?? '';
      
      // Only save cache if user is logged in
      if (userId.isNotEmpty && _commentRepliesCache.isNotEmpty) {
        print('User ID is available ($userId) and cache has ${_commentRepliesCache.length} entries');
        
        // Print some debug info about the cache content
        _commentRepliesCache.forEach((commentId, replies) {
          print('Comment $commentId has ${replies.length} replies in cache');
        });
        
        final String repliesJson = json.encode(_commentRepliesCache);
        print('Encoded JSON size: ${repliesJson.length} bytes');
        
        await prefs.setString('${_commentRepliesKey}_$userId', repliesJson);
        
        int totalReplies = 0;
        _commentRepliesCache.forEach((_, replies) {
          totalReplies += replies.length;
        });
        
        print('Successfully saved replies for ${_commentRepliesCache.length} comments, total $totalReplies replies to cache');
        
        // Verify the save worked
        final savedJson = prefs.getString('${_commentRepliesKey}_$userId');
        print('Verification - saved data exists: ${savedJson != null}');
      } else {
        if (userId.isEmpty) {
          print('Cannot save replies cache: No user ID available');
        } else {
          print('Not saving empty replies cache');
        }
      }
    } catch (e) {
      print('Error saving replies cache: $e');
    }
  }
  
  // Update comment replies cache for a specific comment
  void _updateRepliesCache(String commentId, List<Comment> replies) {
    try {
      print('Updating replies cache for comment $commentId with ${replies.length} replies');
      
      if (replies.isEmpty) {
        if (_commentRepliesCache.containsKey(commentId)) {
          print('Removing empty replies for comment $commentId from cache');
          _commentRepliesCache.remove(commentId);
        }
      } else {
        // Convert each reply to JSON, carefully handling potential errors
        List<Map<String, dynamic>> repliesJson = [];
        
        for (var reply in replies) {
          try {
            // Make sure each reply has the correct parent reference
            Map<String, dynamic> replyJson = reply.toJson();
            
            // Ensure parentComment is set correctly
            if (replyJson['parentComment'] == null || replyJson['parentComment'].toString().isEmpty) {
              replyJson['parentComment'] = commentId;
            }
            
            repliesJson.add(replyJson);
          } catch (e) {
            print('Error converting reply to JSON: $e');
            // Skip this reply if it can't be converted to JSON
          }
        }
        
        if (repliesJson.isNotEmpty) {
          print('Saving ${repliesJson.length} replies for comment $commentId to cache');
          _commentRepliesCache[commentId] = repliesJson;
        }
      }
      
      // Save the updated cache
      _saveRepliesCache();
    } catch (e) {
      print('Error in _updateRepliesCache: $e');
    }
  }
  
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

    print('Loading comments for post $postId, loadMore=$loadMore');
    
    // Store existing comments and their replies before reloading
    Map<String, List<Comment>> existingRepliesMap = {};
    if (!loadMore && _comments.isNotEmpty) {
      print('Preserving existing comment replies before reload');
      // Before clearing comments, save all the replies for each parent comment
      for (var comment in _comments) {
        if (comment.replies != null && comment.replies!.isNotEmpty) {
          existingRepliesMap[comment.id] = comment.replies!;
          // Also save to persistent cache
          _updateRepliesCache(comment.id, comment.replies!);
          print('Saving ${comment.replies!.length} replies for comment ${comment.id}');
        }
      }
      print('Preserved replies for ${existingRepliesMap.length} comments, total ${existingRepliesMap.values.fold(0, (total, replies) => total + replies.length)} replies');
    }

    if (!loadMore) {
      _commentsStatus = CommunityStatus.loading;
      _currentCommentsPage = 1;
      _comments = [];
    }
    
    _errorMessage = null;
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
      
      final List<dynamic> commentsData = result['comments'];
      print('Received ${commentsData.length} comments from API');
      
      // Early debug: check what's in our persistent cache
      print('Current _commentRepliesCache has ${_commentRepliesCache.length} comment entries');
      _commentRepliesCache.forEach((commentId, replies) {
        print('Cache entry for comment $commentId has ${replies.length} replies');
      });
      
      final List<Comment> newComments = commentsData.map((commentData) {
        Comment comment = Comment.fromJson(commentData);
        final String commentId = comment.id;
        print('Processing comment $commentId from API');
        
        int repliesCount = comment.replies?.length ?? 0;
        if (repliesCount > 0) {
          print('Comment $commentId has $repliesCount replies from API');
        }
        
        // Apply cached like status
        if (_likedCommentIds.contains(commentId)) {
          comment = Comment(
            id: comment.id,
            content: comment.content,
            author: comment.author,
            postId: comment.postId,
            parentCommentId: comment.parentCommentId,
            likeCount: comment.likeCount,
            isLiked: true,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            replies: comment.replies?.map((reply) {
              // Also apply cached like status to replies
              if (_likedCommentIds.contains(reply.id)) {
                return Comment(
                  id: reply.id,
                  content: reply.content,
                  author: reply.author,
                  postId: reply.postId,
                  parentCommentId: reply.parentCommentId,
                  likeCount: reply.likeCount,
                  isLiked: true,
                  createdAt: reply.createdAt,
                  updatedAt: reply.updatedAt,
                  replies: reply.replies,
                );
              }
              return reply;
            }).toList(),
          );
        }
        
        // Try to restore replies from memory first (current session)
        if (existingRepliesMap.containsKey(commentId)) {
          List<Comment> existingReplies = existingRepliesMap[commentId]!;
          print('Found ${existingReplies.length} saved replies for comment $commentId in memory');
          
          comment = _mergeReplies(comment, existingReplies);
        } 
        // Then try to restore from persistent cache (between app sessions)
        else if (_commentRepliesCache.containsKey(commentId)) {
          try {
            print('Comment $commentId found in persistent cache');
            List<Map<String, dynamic>> cachedRepliesJson = _commentRepliesCache[commentId]!;
            print('Found ${cachedRepliesJson.length} cached replies for comment $commentId in persistent storage');
            
            // Convert cache to Comment objects
            List<Comment> cachedReplies = [];
            for (var replyJson in cachedRepliesJson) {
              try {
                Comment reply = Comment.fromJson(replyJson);
                // Make sure the parentCommentId is correctly set
                if (reply.parentCommentId == null || reply.parentCommentId!.isEmpty) {
                  reply = Comment(
                    id: reply.id,
                    content: reply.content,
                    author: reply.author,
                    postId: reply.postId,
                    parentCommentId: commentId, // Set parent ID explicitly
                    likeCount: reply.likeCount,
                    isLiked: reply.isLiked,
                    createdAt: reply.createdAt,
                    updatedAt: reply.updatedAt,
                    replies: reply.replies,
                  );
                }
                cachedReplies.add(reply);
                print('Successfully restored reply ${reply.id} from cache');
              } catch (e) {
                print('Error parsing cached reply: $e');
              }
            }
                
            comment = _mergeReplies(comment, cachedReplies);
          } catch (e) {
            print('Error restoring replies from cache: $e');
          }
        } else {
          print('No cached replies found for comment $commentId');
        }
        
        return comment;
      }).toList();
      
      if (loadMore) {
        _comments.addAll(newComments);
      } else {
        _comments = newComments;
      }
      
      _commentsTotalCount = result['total'] ?? 0;
      _hasMoreComments = result['hasMore'] ?? false;
      _commentsStatus = CommunityStatus.loaded;
      
      if (_hasMoreComments) {
        _currentCommentsPage++;
      }
      
      // Count total comments with replies for debugging
      int totalReplies = 0;
      for (var comment in _comments) {
        if (comment.replies != null) {
          totalReplies += comment.replies!.length;
          
          // Make sure all displayed replies are properly cached
          if (comment.replies!.isNotEmpty) {
            _updateRepliesCache(comment.id, comment.replies!);
          }
        }
      }
      print('Loaded ${_comments.length} comments with $totalReplies replies total');
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
      
      // If this is a top-level comment (not a reply), add it to the beginning of our comments list
      if (parentCommentId == null) {
        _comments.insert(0, newComment);
        _commentsTotalCount++;
      } else {
        // This is a reply - find the parent comment and add this as a reply
        final parentIndex = _comments.indexWhere((c) => c.id == parentCommentId);
        if (parentIndex >= 0) {
          final parentComment = _comments[parentIndex];
          final List<Comment> updatedReplies = [
            ...parentComment.replies ?? [],
            newComment,
          ];
          
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
          
          // Save the replies to persistent storage
          _updateRepliesCache(parentComment.id, updatedReplies);
        } else {
          print('Warning: Could not find parent comment with ID $parentCommentId to attach reply');
          
          // Try to save the reply to the cache anyway, even if the parent isn't in the current view
          if (_commentRepliesCache.containsKey(parentCommentId)) {
            List<Map<String, dynamic>> existingReplies = _commentRepliesCache[parentCommentId]!;
            existingReplies.add(newComment.toJson());
            _commentRepliesCache[parentCommentId] = existingReplies;
          } else {
            _commentRepliesCache[parentCommentId] = [newComment.toJson()];
          }
          _saveRepliesCache();
        }
      }
      
      notifyListeners();
      return newComment;
    } catch (e) {
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

      // Find the post in our list
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      final isCurrentlyLiked = postIndex >= 0 ? _posts[postIndex].isLiked : false;
      
      // Optimistically update the UI
      if (postIndex >= 0) {
        final currentLikeCount = _posts[postIndex].likeCount;
        final updatedPost = _posts[postIndex].copyWith(
          isLiked: !isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1
        );
        _posts[postIndex] = updatedPost;
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
      
      // Update the post with the server-confirmed like status
      if (result.containsKey('isLiked') && postIndex >= 0) {
        bool serverLikeStatus = result['isLiked'];
        
        // Update the cached like status with server response
        _updatePostLikeCache(postId, serverLikeStatus);
        
        // If server response differs from our optimistic update, correct it
        if (_posts[postIndex].isLiked != serverLikeStatus) {
          final currentLikeCount = _posts[postIndex].likeCount;
          final updatedPost = _posts[postIndex].copyWith(
            isLiked: serverLikeStatus,
            likeCount: serverLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1
          );
          _posts[postIndex] = updatedPost;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error toggling post like: $e');
      
      // Revert the optimistic update in case of error
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex >= 0) {
        final isCurrentlyLiked = !_posts[postIndex].isLiked; // It was toggled already
        final currentLikeCount = _posts[postIndex].likeCount;
        final updatedPost = _posts[postIndex].copyWith(
          isLiked: isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount + 1 : currentLikeCount - 1
        );
        _posts[postIndex] = updatedPost;
        
        // Revert the cache update
        _updatePostLikeCache(postId, isCurrentlyLiked);
      }
      
      if (_selectedPost?.id == postId) {
        final isCurrentlyLiked = !_selectedPost!.isLiked; // It was toggled already
        final currentLikeCount = _selectedPost!.likeCount;
        _selectedPost = _selectedPost!.copyWith(
          isLiked: isCurrentlyLiked,
          likeCount: isCurrentlyLiked ? currentLikeCount + 1 : currentLikeCount - 1
        );
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
  Comment _mergeReplies(Comment comment, List<Comment> additionalReplies) {
    if (additionalReplies.isEmpty) return comment;
    
    // If the comment already has replies from the API
    if (comment.replies != null && comment.replies!.isNotEmpty) {
      print('Merging ${additionalReplies.length} additional replies with ${comment.replies!.length} existing replies for comment ${comment.id}');
      
      // Create a set of existing reply IDs to avoid duplicates
      Set<String> existingReplyIds = comment.replies!.map((r) => r.id).toSet();
      
      // Create a new combined list
      List<Comment> combinedReplies = List.from(comment.replies!);
      
      // Add any replies that aren't already in the comment
      for (var additionalReply in additionalReplies) {
        if (!existingReplyIds.contains(additionalReply.id)) {
          print('Adding saved reply ${additionalReply.id} to comment ${comment.id}');
          combinedReplies.add(additionalReply);
        }
      }
      
      // Create a new comment with the combined replies
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
        replies: combinedReplies,
      );
    } else {
      // If the comment has no replies, just use the additional ones
      print('API returned no replies for comment ${comment.id}, restoring ${additionalReplies.length} saved replies');
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
        replies: additionalReplies,
      );
    }
  }
} 