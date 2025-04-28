import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/community/post.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../../core/constants/cloudinary_constants.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../community/post_detail_screen.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../community/update_post_screen.dart';
import '../community/create_post_screen.dart';
import '../../widgets/common_widgets.dart';
import '../analytics/analytics_screen.dart';

// App-wide primary blue color
const Color kPrimaryBlue = Color(0xFF29B6F6);

extension UserStats on User {
  int get streakDays => 0; // TODO: Implement streak days calculation
  int get coins => 0; // TODO: Implement coins calculation
  List<String> get earnedBadges => []; // TODO: Implement badges
  String? get selectedSkill => null; // TODO: Implement selected skill
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingBio = false;
  bool _isLoading = false;
  File? _imageFile;
  bool _isUploadingImage = false;
  double _uploadProgress = 0;

  // Controllers
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    
    // Schedule the data loading after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _bioController = TextEditingController();
  }

  Future<void> _loadUserPosts(String userId) async {
    if (!mounted) return;
    
    final communityViewModel = Provider.of<CommunityViewModel>(context, listen: false);
    try {
      await communityViewModel.loadUserPosts(userId);
    } catch (e) {
      print('Error loading user posts: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load posts: ${e.toString()}');
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

    try {
      setState(() => _isLoading = true);

      if (!authViewModel.isAuthenticated) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        if (!authViewModel.isAuthenticated) {
          context.go('/login');
          return;
        }
      }

      final profile = await profileViewModel.getUserProfile(forceRefresh: true);
      if (!mounted) return;

      if (profile == null) {
        // _showErrorSnackBar('Could not load profile data');
        // return;
      }

      await _loadUserPosts(profile!.id);

    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });

        _showImageConfirmationDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image. Please try again.');
    }
  }

  void _showImageConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Profile Picture'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_isUploadingImage) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isUploadingImage
                    ? null
                    : () {
                  setState(() => _imageFile = null);
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: kPrimaryBlue)),
              ),
              ElevatedButton(
                onPressed: _isUploadingImage
                    ? null
                    : () async {
                  setDialogState(() {
                    _isUploadingImage = true;
                  });

                  try {
                    final profileViewModel = Provider.of<ProfileViewModel>(
                        context,
                        listen: false
                    );

                    await profileViewModel.updateProfileImage(
                      _imageFile!,
                      onProgress: (progress) {
                        setDialogState(() {
                          _uploadProgress = progress;
                        });
                      },
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Profile picture updated successfully!');
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      _showErrorSnackBar('Failed to update profile picture: ${e.toString()}');
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isUploadingImage = false;
                        _uploadProgress = 0;
                        _imageFile = null;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future _saveBio() async {
    if (_bioController.text.trim().isEmpty) {
      _showErrorSnackBar('Bio cannot be empty');
      return;
    }

    try {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      await profileViewModel.updateBio(_bioController.text.trim());

      if (mounted) {
        setState(() => _isEditingBio = false);
        _showSuccessSnackBar('Bio updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update bio. Please try again.');
      }
    }
  }

  void _navigateToSettings() {
    context.push('/settings');
  }

  Widget _buildUserPosts() {
    return Consumer<CommunityViewModel>(
      builder: (context, communityViewModel, _) {
        final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
        
        if (communityViewModel.userPostsStatus == CommunityStatus.loading) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue)));
        }
        
        if (communityViewModel.userPostsStatus == CommunityStatus.error) {
          return Column(
            children: [
              Text(communityViewModel.errorMessage ?? 'Error loading posts'),
              ElevatedButton(
                onPressed: () => _loadUserPosts(profileViewModel.currentProfile!.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          );
        }

        if (communityViewModel.userPosts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kPrimaryBlue.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.post_add,
                  size: 48,
                  color: kPrimaryBlue.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your learning journey with the community!',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    ).then((_) {
                      _loadUserPosts(profileViewModel.currentProfile!.id);
                    });
                  },
                  backgroundColor: kPrimaryBlue,
                  child: const Icon(Icons.add),
                ).animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),
              ],
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: communityViewModel.userPosts.length,
          itemBuilder: (context, index) {
            final post = communityViewModel.userPosts[index];
            return _buildPostCard(post);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryBlue.withOpacity(0.1),
                  backgroundImage: post.author.avatar != null
                      ? NetworkImage(post.author.avatar!)
                      : null,
                  child: post.author.avatar == null
                      ? Icon(Icons.person, color: kPrimaryBlue)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.username,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.author.id == Provider.of<AuthViewModel>(context, listen: false).user?.id)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: kPrimaryBlue.withOpacity(0.6),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToUpdatePost(post);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(post.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: kPrimaryBlue),
                            const SizedBox(width: 8),
                            const Text('Edit Post'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Delete Post'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              post.title ?? '',
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          if (post.images != null && post.images.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images!.length,
                  itemBuilder: (context, imageIndex) {
                    final transformedUrl = CloudinaryConstants.getPostImageUrl(post.images![imageIndex]);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: transformedUrl,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: post.likeCount.toString(),
                  color: post.isLiked ? kPrimaryBlue : null,
                  onTap: () {
                    final communityViewModel = Provider.of<CommunityViewModel>(context, listen: false);
                    communityViewModel.togglePostLike(post.id);
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: post.commentCount.toString(),
                  onTap: () => _navigateToPostDetail(post.id),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  label: 'Save',
                  onTap: () {
                    // TODO: Implement save post functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 600.ms)
     .moveY(begin: 20, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: color ?? kPrimaryBlue.withOpacity(0.7),
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color ?? kPrimaryBlue.withOpacity(0.7),
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final isWeb = kIsWeb;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: kPrimaryBlue,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // For wider screens - stats in a row with better spacing and larger elements
  Widget _buildWideStatsLayout(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWebStatCard(
          context, 
          'Streak', 
          '${user.streakDays} days', 
          Icons.local_fire_department,
          Colors.orange.shade700,
          screenWidth
        ),
        const SizedBox(width: 24),
        _buildWebStatCard(
          context, 
          'Coins', 
          '${user.coins}', 
          Icons.monetization_on,
          Colors.amber.shade700,
          screenWidth
        ),
        const SizedBox(width: 24),
        _buildWebStatCard(
          context, 
          'Badges', 
          '${user.earnedBadges?.length ?? 0}', 
          Icons.emoji_events,
          Colors.amber.shade400,
          screenWidth
        ),
      ],
    );
  }

  // Enhanced web stat card with larger elements
  Widget _buildWebStatCard(BuildContext context, String title, String value, IconData icon, Color iconColor, double screenWidth) {
    // Dynamic sizing based on screen width
    final cardWidth = screenWidth > 1600 ? 220.0 :
                     screenWidth > 1200 ? 180.0 :
                     screenWidth > 992 ? 160.0 : 140.0;
    
    final iconSize = screenWidth > 1600 ? 60.0 :
                    screenWidth > 1200 ? 50.0 :
                    screenWidth > 992 ? 45.0 : 40.0;
                    
    final valueFontSize = screenWidth > 1600 ? 36.0 :
                         screenWidth > 1200 ? 32.0 :
                         screenWidth > 992 ? 28.0 : 24.0;
                         
    final titleFontSize = screenWidth > 1600 ? 18.0 :
                         screenWidth > 1200 ? 16.0 :
                         screenWidth > 992 ? 15.0 : 14.0;
    
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(screenWidth > 1200 ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
          SizedBox(height: screenWidth > 1200 ? 16 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth > 1200 ? 8 : 6),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // For normal stats layout in a column with enhanced styling
  Widget _buildNormalStatsLayout(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWebStatCard(
          context, 
          'Streak', 
          '${user.streakDays} days', 
          Icons.local_fire_department,
          Colors.orange.shade700,
          screenWidth
        ),
        _buildWebStatCard(
          context, 
          'Coins', 
          '${user.coins}', 
          Icons.monetization_on,
          Colors.amber.shade700,
          screenWidth
        ),
        _buildWebStatCard(
          context, 
          'Badges', 
          '${user.earnedBadges?.length ?? 0}', 
          Icons.emoji_events,
          Colors.amber.shade400,
          screenWidth
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kPrimaryBlue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final communityViewModel = Provider.of<CommunityViewModel>(context, listen: false);
                await communityViewModel.deletePost(postId);
                
                if (mounted) {
                  setState(() {
                    communityViewModel.userPosts.removeWhere((post) => post.id == postId);
                  });
                  
                  _showSuccessSnackBar('Post deleted successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Failed to delete post: ${e.toString()}');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToUpdatePost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdatePostScreen(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group,color: kPrimaryBlue),
            onPressed: () {
              GoRouter.of(context).go('/friends');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: kPrimaryBlue,
            ),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Consumer2<AuthViewModel, ProfileViewModel>(
        builder: (context, authViewModel, profileViewModel, _) {
          if (!authViewModel.isAuthenticated || profileViewModel.isLoading || _isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
              ),
            );
          }

          final user = profileViewModel.currentProfile;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No profile data available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadInitialData();
            },
            color: kPrimaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Profile picture
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'profile_image',
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kPrimaryBlue.withOpacity(0.3), width: 3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: _buildProfileImage(user),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User name
                  Text(
                    user.username,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // User email
                  Text(
                    user.email ?? 'email@example.com',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(context, 'Streak', '${user.streakDays ?? 0} days', Icons.local_fire_department),
                      _buildStatCard(context, 'Coins', '${user.coins ?? 0}', Icons.monetization_on),
                      _buildStatCard(context, 'Badges', '${user.earnedBadges?.length ?? 0}', Icons.emoji_events),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalyticsScreen(userId: user.id),
                        ),
                      );
                    },
                    icon: Icon(Icons.insights, color: kPrimaryBlue),
                    label: Text('View Analytics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // User's Posts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Posts',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildUserPosts(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(User? profile) {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
      );
    }

    if (profile?.avatar != null && profile!.avatar!.isNotEmpty) {
      if (profile.avatar!.startsWith('http')) {
        final transformedUrl = CloudinaryConstants.getProfileImageUrl(profile.avatar!);

        return CachedNetworkImage(
          imageUrl: transformedUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        );
      } else {
        return Image.asset(
          'assets/images/${profile.avatar}.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFacebookStyleWebLayout(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Dynamic content width based on screen size with limits for very large screens
    final contentWidth = screenWidth > 1800 ? 1600.0 :
                        screenWidth > 1600 ? 1400.0 :
                        screenWidth > 1200 ? 1100.0 : 
                        screenWidth > 992 ? screenWidth * 0.85 : 
                        screenWidth * 0.95;
    
    // Adjust cover height for a better experience on smaller screens
    final coverHeight = screenWidth > 1600 ? 400.0 :
                       screenWidth > 1200 ? 350.0 :
                       screenWidth > 992 ? 300.0 : 250.0;
    
    // Larger profile image on web                   
    final profileImageSize = screenWidth > 1600 ? 200.0 :
                           screenWidth > 1200 ? 180.0 :
                           screenWidth > 992 ? 160.0 : 140.0;
    
    // Responsive column layout ratio that changes with screen size                    
    final leftColumnRatio = screenWidth > 1600 ? 0.28 :
                          screenWidth > 1200 ? 0.3 :
                          screenWidth > 992 ? 0.35 : 0.4;
    
    // Font size adjustments based on screen size
    final headlineFontSize = screenWidth > 1600 ? 34.0 :
                           screenWidth > 1200 ? 30.0 :
                           screenWidth > 992 ? 28.0 : 24.0;
                           
    final subtitleFontSize = screenWidth > 1600 ? 20.0 :
                           screenWidth > 1200 ? 18.0 :
                           screenWidth > 992 ? 16.0 : 14.0;
    
    // Card padding based on screen size
    final cardPadding = screenWidth > 1200 ? 30.0 :
                       screenWidth > 992 ? 24.0 : 16.0;
    
    return Column(
      children: [
        // Facebook-style cover image
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Cover photo
            Container(
              width: double.infinity,
              height: coverHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryBlue.withOpacity(0.5),
                    kPrimaryBlue.withOpacity(0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: IconButton.filled(
                      onPressed: () {
                        // TODO: Add cover photo changing functionality
                      },
                      icon: Icon(Icons.camera_alt, color: Colors.white, size: screenWidth > 992 ? 24 : 20),
                      style: IconButton.styleFrom(
                        backgroundColor: kPrimaryBlue.withOpacity(0.8),
                        padding: EdgeInsets.all(screenWidth > 992 ? 16 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile info bar that overlaps cover photo at bottom
            Container(
              width: contentWidth,
              margin: EdgeInsets.only(bottom: screenWidth > 992 ? -70 : -60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Profile picture - positioned to overlap
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'profile_image',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(profileImageSize / 2),
                              child: SizedBox(
                                width: profileImageSize,
                                height: profileImageSize,
                                child: _buildProfileImage(user),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.all(screenWidth > 992 ? 8 : 6),
                              decoration: BoxDecoration(
                                color: kPrimaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: screenWidth > 992 ? 20 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: screenWidth > 992 ? 30 : 24),
                  
                  // User name and basic info
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: screenWidth > 992 ? 80 : 70),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: headlineFontSize,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            user.email ?? 'email@example.com',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: subtitleFontSize,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action buttons aligned with name
                  Padding(
                    padding: EdgeInsets.only(bottom: screenWidth > 992 ? 80 : 70),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnalyticsScreen(userId: user.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.insights),
                          label: Text(screenWidth > 768 ? 'Analytics' : ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth > 992 ? 20 : 16, 
                              vertical: screenWidth > 992 ? 14 : 12
                            ),
                            textStyle: TextStyle(
                              fontSize: screenWidth > 992 ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth > 992 ? 12 : 8),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement edit profile functionality
                          },
                          icon: const Icon(Icons.edit, color: kPrimaryBlue),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.all(screenWidth > 992 ? 14 : 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: screenWidth > 992 ? 80 : 70),
        
        // Main content area
        Container(
          width: contentWidth,
          padding: EdgeInsets.symmetric(horizontal: screenWidth > 992 ? 0 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar - Info cards
              SizedBox(
                width: contentWidth * leftColumnRatio,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(context, user),
                    SizedBox(height: screenWidth > 992 ? 24 : 20),
                    _buildStatsCard(context, user),
                    SizedBox(height: screenWidth > 992 ? 24 : 20),
                    _buildFriendsCard(context),
                  ],
                ),
              ),
              
              SizedBox(width: screenWidth > 992 ? 30 : 20),
              
              // Right area - Posts
              Expanded(
                child: Column(
                  children: [
                    _buildCreatePostCard(context),
                    SizedBox(height: screenWidth > 992 ? 24 : 20),
                    _buildUserPosts(),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    // Card padding based on screen size
    final cardPadding = screenWidth > 1200 ? 30.0 :
                       screenWidth > 992 ? 24.0 : 16.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isWideScreen ? 24 : 20,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement edit bio functionality
                  },
                  icon: Icon(Icons.edit, size: isWideScreen ? 22 : 18),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  color: kPrimaryBlue,
                ),
              ],
            ),
            Divider(thickness: isWideScreen ? 1.5 : 1.2),
            SizedBox(height: isWideScreen ? 20 : 12),
            
            // Bio info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, 
                  size: isWideScreen ? 26 : 22, 
                  color: Colors.grey.shade600
                ),
                SizedBox(width: isWideScreen ? 16 : 12),
                Expanded(
                  child: Text(
                    'Learning enthusiast focused on improving language skills.',
                    style: TextStyle(
                      fontSize: isWideScreen ? 17 : 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWideScreen ? 24 : 16),
            
            // Email info
            Row(
              children: [
                Icon(Icons.email_outlined, 
                  size: isWideScreen ? 26 : 22, 
                  color: Colors.grey.shade600
                ),
                SizedBox(width: isWideScreen ? 16 : 12),
                Expanded(
                  child: Text(
                    user.email ?? 'email@example.com',
                    style: TextStyle(
                      fontSize: isWideScreen ? 17 : 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    // Card padding based on screen size
    final cardPadding = screenWidth > 1200 ? 30.0 :
                       screenWidth > 992 ? 24.0 : 16.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stats',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isWideScreen ? 24 : 20,
              ),
            ),
            Divider(thickness: isWideScreen ? 1.5 : 1.2),
            SizedBox(height: isWideScreen ? 20 : 12),
            
            // Responsive layout for stats based on screen width
            screenWidth > 1400 
                ? _buildWideStatsLayout(context, user)
                : _buildNormalStatsLayout(context, user),
            
            SizedBox(height: isWideScreen ? 30 : 20),
            // View analytics button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsScreen(userId: user.id),
                    ),
                  );
                },
                icon: Icon(Icons.analytics, size: isWideScreen ? 22 : 18),
                label: Text(
                  'View Detailed Analytics',
                  style: TextStyle(
                    fontSize: isWideScreen ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryBlue,
                  side: BorderSide(color: kPrimaryBlue, width: 1.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 24 : 20,
                    vertical: isWideScreen ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWideScreen ? 10 : 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    // Card padding based on screen size
    final cardPadding = screenWidth > 1200 ? 30.0 :
                       screenWidth > 992 ? 24.0 : 16.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friends',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isWideScreen ? 24 : 20,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/friends');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: isWideScreen ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(thickness: isWideScreen ? 1.5 : 1.2),
            SizedBox(height: isWideScreen ? 20 : 12),
            
            // PLACEHOLDER: Friends list would go here - sample placeholders
            if (screenWidth > 1200)
              _buildWideScreenFriendsPlaceholder()
            else
              _buildNormalScreenFriendsPlaceholder(),
              
            SizedBox(height: isWideScreen ? 30 : 20),
            
            // Add friend button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/friends');
                },
                icon: Icon(Icons.person_add, size: isWideScreen ? 22 : 18),
                label: Text(
                  'Find Friends',
                  style: TextStyle(
                    fontSize: isWideScreen ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryBlue,
                  side: BorderSide(color: kPrimaryBlue, width: 1.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 24 : 20,
                    vertical: isWideScreen ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWideScreen ? 10 : 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // For wider screens - friends in a grid
  Widget _buildWideScreenFriendsPlaceholder() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildFriendPlaceholder(context);
      },
    );
  }

  // For normal screens - friends in a row
  Widget _buildNormalScreenFriendsPlaceholder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) => _buildFriendPlaceholder(context)),
    );
  }

  Widget _buildFriendPlaceholder(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    return Column(
      children: [
        CircleAvatar(
          radius: isWideScreen ? 38 : 28,
          backgroundColor: Colors.grey[200],
          child: Icon(
            Icons.person,
            size: isWideScreen ? 36 : 28,
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: isWideScreen ? 12 : 8),
        Container(
          width: isWideScreen ? 80 : 60,
          height: isWideScreen ? 16 : 14,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCreatePostCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    // Card padding based on screen size
    final cardPadding = screenWidth > 1200 ? 30.0 :
                       screenWidth > 992 ? 24.0 : 16.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isWideScreen ? 28 : 24,
                  backgroundImage: Provider.of<ProfileViewModel>(context).currentProfile?.avatar != null
                      ? NetworkImage(Provider.of<ProfileViewModel>(context).currentProfile!.avatar!)
                      : null,
                  child: Provider.of<ProfileViewModel>(context).currentProfile?.avatar == null
                      ? Icon(Icons.person, size: isWideScreen ? 26 : 22)
                      : null,
                ),
                SizedBox(width: isWideScreen ? 20 : 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePostScreen(),
                        ),
                      ).then((_) {
                        _loadUserPosts(Provider.of<ProfileViewModel>(context, listen: false).currentProfile!.id);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 24 : 20, 
                        vertical: isWideScreen ? 20 : 16
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: isWideScreen ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWideScreen ? 20 : 16),
            Divider(thickness: isWideScreen ? 1.2 : 1),
            // Use responsive layout for buttons based on screen width
            screenWidth > 768 ? _buildWidePostActions() : _buildNormalPostActions(),
          ],
        ),
      ),
    );
  }
  
  // For wider screens - buttons in a row with more space
  Widget _buildWidePostActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWideScreen ? 12 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildPostActionButton(Icons.photo_library, Colors.green.shade600, 'Photo')),
          const SizedBox(width: 8),
          Expanded(child: _buildPostActionButton(Icons.celebration, Colors.purple.shade400, 'Achievement')),
          const SizedBox(width: 8),
          Expanded(child: _buildPostActionButton(Icons.article, Colors.blue.shade400, 'Article')),
        ],
      ),
    );
  }
  
  // For narrower screens - buttons fit to content
  Widget _buildNormalPostActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWideScreen ? 12 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPostActionButton(Icons.photo_library, Colors.green.shade600, 'Photo'),
          _buildPostActionButton(Icons.celebration, Colors.purple.shade400, 'Achievement'),
        ],
      ),
    );
  }
  
  // Helper for post action buttons
  Widget _buildPostActionButton(IconData icon, Color iconColor, String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 992;
    
    return TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        ).then((_) {
          _loadUserPosts(Provider.of<ProfileViewModel>(context, listen: false).currentProfile!.id);
        });
      },
      icon: Icon(
        icon, 
        color: iconColor,
        size: isWideScreen ? 26 : 22
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isWideScreen ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 20 : 16, 
          vertical: isWideScreen ? 14 : 10
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWideScreen ? 12 : 8),
        ),
      ),
    );
  }
}