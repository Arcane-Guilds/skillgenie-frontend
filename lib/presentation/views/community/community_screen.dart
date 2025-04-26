import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/community/post.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/loading_indicator.dart';
import 'create_post_screen.dart';
import '../../../core/theme/app_theme.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Python', 'JavaScript', 'Data Science', 'AI/ML', 'Popular'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().loadPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor.withOpacity(0.97),
      body: Consumer<CommunityViewModel>(
        builder: (context, viewModel, child) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                snap: true,
                title: Text(
                  'Community',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                centerTitle: false,
                backgroundColor: AppTheme.surfaceColor,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () {
                      // TODO: Open notifications
                    },
                  ),
                ],
              ),
            ],
            body: Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: viewModel.postsStatus == CommunityStatus.loading && viewModel.posts.isEmpty
                      ? const Center(child: LoadingIndicator())
                      : viewModel.errorMessage != null && viewModel.posts.isEmpty
                          ? _buildErrorState(viewModel)
                          : viewModel.posts.isEmpty
                              ? _buildEmptyState(viewModel)
                              : RefreshIndicator(
                                  color: AppTheme.primaryColor,
                                  onRefresh: () => viewModel.loadPosts(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 100),
                                    itemCount: viewModel.posts.length,
                                    itemBuilder: (context, index) {
                                      return _buildPostCard(context, viewModel.posts[index], index);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          ).then((_) {
            context.read<CommunityViewModel>().loadPosts();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ).animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search community posts...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppTheme.surfaceColor,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CommunityViewModel viewModel) {
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
            'Error loading posts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
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
    );
  }

  Widget _buildEmptyState(CommunityViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No community posts yet',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start a discussion!',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              ).then((_) {
                viewModel.loadPosts();
              });
            },
            child: const Text('Create New Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'avatar-${post.id}',
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      backgroundImage: post.author.avatar != null
                          ? NetworkImage(post.author.avatar!)
                          : null,
                      child: post.author.avatar == null
                          ? Text(
                              post.author.username.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
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
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondaryColor.withOpacity(0.6),
                    ),
                    onPressed: () {
                      // TODO: Show post options
                    },
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppTheme.textSecondaryColor.withOpacity(0.8),
                ),
              ),
            ),
            
            if (post.images.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    post.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.thumb_up_outlined,
                    label: post.likeCount.toString(),
                    onTap: () {
                      context.read<CommunityViewModel>().togglePostLike(post.id);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: post.commentCount.toString(),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(postId: post.id),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      // TODO: Share post
                    },
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.bookmark_border,
                    label: 'Save',
                    onTap: () {
                      // TODO: Save post
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: AppTheme.textSecondaryColor.withOpacity(0.7),
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppTheme.textSecondaryColor.withOpacity(0.7),
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
} 