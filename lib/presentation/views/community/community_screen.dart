import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../data/models/community/post.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/loading_indicator.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load posts when the screen is first shown
      context.read<CommunityViewModel>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CommunityViewModel>().loadPosts();
            },
          ),
        ],
      ),
      body: Consumer<CommunityViewModel>(
        builder: (context, viewModel, child) {
          // Always wrap in RefreshIndicator to allow pull-to-refresh
          return RefreshIndicator(
            onRefresh: () => viewModel.loadPosts(),
            child: _buildContent(context, viewModel),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          ).then((_) {
            // Refresh posts when returning from create post screen
            context.read<CommunityViewModel>().loadPosts();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, CommunityViewModel viewModel) {
    // Show loading indicator when posts are loading initially
    if (viewModel.postsStatus == CommunityStatus.loading && viewModel.posts.isEmpty) {
      return ListView(
        // Add ListView to make RefreshIndicator work
        children: const [
          SizedBox(height: 100),
          Center(child: LoadingIndicator()),
        ],
      );
    }

    // Show error message if there's an error
    if (viewModel.errorMessage != null && viewModel.posts.isEmpty) {
      return ListView(
        // Add ListView to make RefreshIndicator work
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading posts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(viewModel.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    viewModel.resetError();
                    viewModel.loadPosts();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show empty state if there are no posts
    if (viewModel.posts.isEmpty) {
      return ListView(
        // Add ListView to make RefreshIndicator work
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Be the first to share something with the community!'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    ).then((_) {
                      // Refresh posts when returning from create post screen
                      viewModel.loadPosts();
                    });
                  },
                  child: const Text('Create Post'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show posts if available
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: viewModel.posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(context, viewModel.posts[index]);
      },
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.go('/post/${post.id}');
        },
        borderRadius: BorderRadius.circular(12),
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
                    
                    // Comment button
                    InkWell(
                      onTap: () {
                        context.go('/post/${post.id}');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.comment_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(post.commentCount.toString()),
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
      ),
    );
  }
} 