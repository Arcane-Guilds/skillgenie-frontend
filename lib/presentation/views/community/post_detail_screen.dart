import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../data/models/community/post.dart';
import '../../../data/models/community/comment.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/theme/app_theme.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToUsername;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final viewModel = context.read<CommunityViewModel>();
    await viewModel.loadPostById(widget.postId);
    await viewModel.loadComments(widget.postId);
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
      _commentController.text = '';
    });
    
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
      _commentController.text = '';
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final viewModel = context.read<CommunityViewModel>();
      await viewModel.createComment(
        widget.postId,
        _commentController.text.trim(),
        parentCommentId: _replyToCommentId,
      );
      
      _commentController.clear();
      _cancelReply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityViewModel>(
      builder: (context, viewModel, child) {
        String appBarTitle = 'Post Details';
        
        if (viewModel.selectedPost != null) {
          final postTitle = viewModel.selectedPost!.title;
          if (postTitle.isNotEmpty) {
            appBarTitle = postTitle.length > 25 
                ? '${postTitle.substring(0, 22)}...' 
                : postTitle;
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              appBarTitle,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (viewModel.postDetailStatus == CommunityStatus.loading) {
                return const Center(child: LoadingIndicator());
              }

              final post = viewModel.selectedPost;
              if (post == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Post not found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This post might have been deleted or is no longer available.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Post content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post card
                            _buildPostCard(context, post),
                            
                            const SizedBox(height: 24),
                            
                            // Comments section title
                            Row(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Comments (${post.commentCount})',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Comments list
                            _buildCommentsList(viewModel),
                            
                            // Load more comments button
                            if (viewModel.hasMoreComments)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ElevatedButton(
                                    onPressed: viewModel.commentsStatus == CommunityStatus.loading
                                        ? null
                                        : () => viewModel.loadComments(post.id, loadMore: true),
                                    child: viewModel.commentsStatus == CommunityStatus.loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Load More'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Comment input
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                    ),
                    child: Column(
                      children: [
                        if (_replyToUsername != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Replying to $_replyToUsername',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _cancelReply,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: _replyToUsername != null
                                      ? 'Reply to $_replyToUsername'
                                      : 'Write a comment...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.backgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _isSubmittingComment ? null : _submitComment,
                              icon: _isSubmittingComment
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send,
                                      color: AppTheme.primaryColor,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info and timestamp
            Row(
              children: [
                Hero(
                  tag: 'avatar-${post.id}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: post.author.avatar != null
                        ? NetworkImage(post.author.avatar!)
                        : null,
                    child: post.author.avatar == null
                        ? Text(
                            post.author.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Post title
            if (post.title.isNotEmpty) ...[
              const SizedBox(height: 12),
              Hero(
                tag: 'title-${post.id}',
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            Hero(
              tag: 'content-${post.id}',
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            
            // Images if any
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Hero(
                        tag: 'image-${post.id}-$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            post.images[index],
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Interaction buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    context.read<CommunityViewModel>().togglePostLike(post.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likeCount.toString(),
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Comment count
                Row(
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.commentCount.toString(),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(CommunityViewModel viewModel) {
    if (viewModel.commentsStatus == CommunityStatus.loading &&
        viewModel.comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: LoadingIndicator()),
      );
    }

    if (viewModel.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'No comments yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to comment!',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: viewModel.comments.map((comment) {
        return _buildCommentItem(context, comment);
      }).toList(),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Container(
      key: ValueKey('comment-${comment.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info and timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: comment.author.avatar != null
                      ? NetworkImage(comment.author.avatar!)
                      : null,
                  child: comment.author.avatar == null
                      ? Text(
                          comment.author.username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Comment content
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: const TextStyle(fontSize: 14),
            ),
            
            // Interaction buttons
            const SizedBox(height: 12),
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    context.read<CommunityViewModel>().toggleCommentLike(comment.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          comment.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: comment.isLiked ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likeCount.toString(),
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Reply button
                InkWell(
                  onTap: () => _startReply(comment.id, comment.author.username),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          color: AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Replies if any
            if (comment.replies != null && comment.replies!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: comment.replies!.map((reply) {
                    return Padding(
                      key: ValueKey('reply-${reply.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply author and timestamp
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: reply.author.avatar != null
                                    ? NetworkImage(reply.author.avatar!)
                                    : null,
                                child: reply.author.avatar == null
                                    ? Text(
                                        reply.author.username.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reply.author.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      timeago.format(reply.createdAt),
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Reply content
                          const SizedBox(height: 4),
                          Text(
                            reply.content,
                            style: const TextStyle(fontSize: 13),
                          ),
                          
                          // Reply interaction buttons
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Like button
                              InkWell(
                                onTap: () {
                                  context.read<CommunityViewModel>().toggleCommentLike(reply.id);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        reply.isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: reply.isLiked ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        reply.likeCount.toString(),
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 