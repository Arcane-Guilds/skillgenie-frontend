import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../data/models/community/post.dart';
import '../../../data/models/community/comment.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/loading_indicator.dart';

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
    
    // Focus the text field
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
        // Determine the app bar title based on the post
        String appBarTitle = 'Post Details';
        
        if (viewModel.selectedPost != null) {
          // Use post title or a shortened version if it's too long
          final postTitle = viewModel.selectedPost!.title;
          if (postTitle.isNotEmpty) {
            // Limit title to 25 characters to avoid overflow
            appBarTitle = postTitle.length > 25 
                ? '${postTitle.substring(0, 22)}...' 
                : postTitle;
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (viewModel.postDetailStatus == CommunityStatus.loading) {
                return const Center(child: LoadingIndicator());
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading post',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(viewModel.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          viewModel.resetError();
                          _loadData();
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.selectedPost == null) {
                return const Center(child: Text('Post not found'));
              }

              final post = viewModel.selectedPost!;

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
                                const Icon(Icons.comment_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  'Comments (${post.commentCount})',
                                  style: Theme.of(context).textTheme.titleMedium,
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
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reply to indicator
                        if (_replyToUsername != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Replying to $_replyToUsername',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _cancelReply,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Comment input field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                minLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _isSubmittingComment
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              onPressed: _isSubmittingComment
                                  ? null
                                  : _submitComment,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info and timestamp
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.author.avatar != null
                      ? NetworkImage(post.author.avatar!)
                      : null,
                  child: post.author.avatar == null
                      ? Text(post.author.username.substring(0, 1).toUpperCase())
                      : null,
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
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Post title (if available)
            if (post.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Post content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(post.content),
            ),
            
            // Images if any
            if (post.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.images[index],
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Interaction buttons
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () {
                      context.read<CommunityViewModel>().togglePostLike(post.id);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: post.isLiked ? Colors.red : null,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(post.likeCount.toString()),
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
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(post.commentCount.toString()),
                    ],
                  ),
                ],
              ),
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
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No comments yet. Be the first to comment!'),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('comments-list-${viewModel.comments.length}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.comments.length,
      itemBuilder: (context, index) {
        return _buildCommentItem(context, viewModel.comments[index]);
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Padding(
      key: ValueKey('comment-${comment.id}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and timestamp
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: comment.author.avatar != null
                          ? NetworkImage(comment.author.avatar!)
                          : null,
                      child: comment.author.avatar == null
                          ? Text(comment.author.username.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.author.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Comment text
                Text(comment.content),
                
                // Interaction buttons
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      // Like button
                      InkWell(
                        onTap: () {
                          context.read<CommunityViewModel>().toggleCommentLike(comment.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: comment.isLiked ? Colors.red : null,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                comment.likeCount.toString(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Reply button
                      InkWell(
                        onTap: () {
                          _startReply(comment.id, comment.author.username);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Replies
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ListView.builder(
                key: ValueKey('replies-${comment.id}-${comment.replies!.length}'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comment.replies!.length,
                itemBuilder: (context, index) {
                  final reply = comment.replies![index];
                  return Padding(
                    key: ValueKey('reply-${reply.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author and timestamp
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: reply.author.avatar != null
                                    ? NetworkImage(reply.author.avatar!)
                                    : null,
                                child: reply.author.avatar == null
                                    ? Text(reply.author.username.substring(0, 1).toUpperCase())
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reply.author.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeago.format(reply.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Reply text
                          Text(
                            reply.content,
                            style: const TextStyle(fontSize: 13),
                          ),
                          
                          // Like button
                          InkWell(
                            onTap: () {
                              context.read<CommunityViewModel>().toggleCommentLike(reply.id);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    reply.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: reply.isLiked ? Colors.red : null,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reply.likeCount.toString(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 