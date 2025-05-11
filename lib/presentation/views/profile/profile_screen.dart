import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:skillGenie/presentation/views/achievements_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';

import '../../../data/models/user_model.dart';
import '../../../data/models/community/post.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../../core/constants/cloudinary_constants.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../community/post_detail_screen.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../community/update_post_screen.dart';
import '../community/create_post_screen.dart';
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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  File? _imageFile;
  bool _isUploadingImage = false;
  double _uploadProgress = 0;
  String? selectedFrame;
  String? selectedDecoration;
  String? selectedBackground;
  bool _pulseValue = false;
  late ConfettiController _confettiController;
  Timer? _pulseTimer;

  // Controllers
  late TextEditingController _bioController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _pulseValue = !_pulseValue;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      if (profileViewModel.currentProfile == null) {
        _loadInitialData();
      }
      _loadEquippedCosmetics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    _confettiController.dispose();
    _pulseTimer?.cancel();
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

      await profileViewModel.fetchUserBadgeCount();
      await _loadUserPosts(profile!.id);

    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEquippedCosmetics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFrame = prefs.getString('selectedFrame');
      selectedDecoration = prefs.getString('selectedDecoration');
      selectedBackground = prefs.getString('selectedBackground');

      // Convert empty strings to null
      if (selectedFrame == '') selectedFrame = null;
      if (selectedDecoration == '') selectedDecoration = null;
      if (selectedBackground == '') selectedBackground = null;
    });

    // Start confetti if decoration is equipped
    if (selectedDecoration == 'decoration_confetti') {
      _confettiController.play();
    }
  }

  Future<void> _saveEquippedCosmetics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFrame', selectedFrame ?? '');
    await prefs.setString('selectedDecoration', selectedDecoration ?? '');
    await prefs.setString('selectedBackground', selectedBackground ?? '');
  }

  Future<void> _unequipCosmetic(String type) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case 'frame':
        setState(() => selectedFrame = null);
        await prefs.setString('selectedFrame', '');
        break;
      case 'decoration':
        setState(() => selectedDecoration = null);
        await prefs.setString('selectedDecoration', '');
        break;
      case 'background':
        setState(() => selectedBackground = null);
        await prefs.setString('selectedBackground', '');
        break;
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
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
                child: const Text('Cancel', style: TextStyle(color: kPrimaryBlue)),
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


  void _navigateToSettings() {
    context.push('/settings');
  }

  Widget _buildUserPosts() {
    return Consumer<CommunityViewModel>(
      builder: (context, communityViewModel, _) {
        final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);

        if (communityViewModel.userPostsStatus == CommunityStatus.loading) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue)));
        }

        if (communityViewModel.userPostsStatus == CommunityStatus.error) {
          return Column(
            children: [
              Text(communityViewModel.errorMessage ?? 'Error loading posts'),
              ElevatedButton(
                onPressed: () {
                  final user = profileViewModel.currentProfile;
                  if (user != null) {
                    _loadUserPosts(user.id);
                  } else {
                    _showErrorSnackBar('No profile data available');
                  }
                },
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
                      final user = profileViewModel.currentProfile;
                      if (user != null) {
                        _loadUserPosts(user.id);
                      } else {
                        _showErrorSnackBar('No profile data available');
                      }
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
                      ? const Icon(Icons.person, color: kPrimaryBlue)
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: kPrimaryBlue),
                            SizedBox(width: 8),
                            Text('Edit Post'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post'),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          if (post.images.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images.length,
                  itemBuilder: (context, imageIndex) {
                    final transformedUrl = CloudinaryConstants.getPostImageUrl(post.images[imageIndex]);
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
    const isWeb = kIsWeb;

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
            'Badges',
            '${user.earnedBadges.length ?? 0}',
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
            'Badges',
            '${user.earnedBadges.length ?? 0}',
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
            child: const Text('Cancel', style: TextStyle(color: kPrimaryBlue)),
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
    // Use context.watch for view models to react to state changes
    final authViewModel = context.watch<AuthViewModel>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final communityViewModel = context.watch<CommunityViewModel>();

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
            icon: const Icon(Icons.group, color: kPrimaryBlue),
            onPressed: () {
              GoRouter.of(context).go('/friends');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: kPrimaryBlue,
            ),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background effect for the entire screen
          if (selectedBackground != null)
            Positioned.fill(
              child: _buildBackgroundEffect(),
            ),

          // Main content
          Builder(
              builder: (context) {
                // --- Loading State ---
                final bool isProfileLoading = profileViewModel.isLoading || (authViewModel.isLoading && !authViewModel.authChecked);
                final bool isPostsLoading = profileViewModel.currentProfile != null &&
                    (communityViewModel.userPostsStatus == CommunityStatus.initial ||
                        communityViewModel.userPostsStatus == CommunityStatus.loading);

                if (isProfileLoading || isPostsLoading) {
                  if (profileViewModel.currentProfile != null &&
                      communityViewModel.userPostsStatus == CommunityStatus.initial) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if(mounted) {
                        _loadUserPosts(profileViewModel.currentProfile!.id);
                      }
                    });
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                    ),
                  );
                }

                // --- Error State ---
                final String? profileError = profileViewModel.errorMessage ?? authViewModel.error;
                final String? postsError = communityViewModel.userPostsStatus == CommunityStatus.error
                    ? communityViewModel.errorMessage
                    : null;
                final String? displayError = profileError ?? postsError;

                if (displayError != null && (profileViewModel.currentProfile == null || postsError != null)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $displayError'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            profileViewModel.clearError();
                            authViewModel.clearError();
                            communityViewModel.resetError();
                            _loadInitialData();
                          },
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

                // --- No Profile Data State ---
                final user = profileViewModel.currentProfile;
                if (user == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No profile data available.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInitialData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reload Profile'),
                        ),
                      ],
                    ),
                  );
                }

                // --- Profile Data Loaded State ---
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
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _buildProfileImage(user),
                                        if (selectedFrame != null)
                                          _buildFrameEffect(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
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
                        // User bio (replace email)
                        Text(
                          (user.bio != null && user.bio!.trim().isNotEmpty)
                              ? user.bio!
                              : 'No bio set.',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(context, 'Streak', '${user.streakDays ?? 0} days', Icons.local_fire_department),
                            _buildStatCard(context, 'Badges', '${profileViewModel.badgeCount}', Icons.emoji_events),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: kPrimaryBlue,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: kPrimaryBlue,
                            dividerHeight: 0,
                            tabs: const [
                              Tab(icon: Icon(Icons.list), text: 'Posts'),
                              Tab(icon: Icon(Icons.emoji_events), text: 'Insights'),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 500, // or MediaQuery.of(context).size.height * 0.6, etc.
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: User Posts
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildUserPosts(),
                              ),
                              // Tab 2: Achievements & Analytics
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Achievements button
                                    Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(18),
                                      color: Colors.white,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AchievementsScreen(userId: user.id),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            gradient: LinearGradient(
                                              colors: [Colors.amber.shade200, Colors.amber.shade400],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.emoji_events, color: Colors.amber.shade800, size: 32),
                                              const SizedBox(width: 16),
                                              const Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Achievements',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'View your badges and milestones',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Analytics button
                                    Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(18),
                                      color: kPrimaryBlue,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AnalyticsScreen(userId: user.id),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(18)),
                                            gradient: LinearGradient(
                                              colors: [kPrimaryBlue, Colors.lightBlueAccent],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.insights, color: Colors.white, size: 32),
                                              SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'View Analytics',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Track your learning progress',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Take Quiz button
                                    Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(18),
                                      color: Colors.deepPurpleAccent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          final String? userJson = prefs.getString("user");
                                          if (userJson != null) {
                                            final user = User.fromJson(jsonDecode(userJson));
                                            if (!mounted) return;
                                            context.push('/quiz/${user.id}');
                                          } else {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('User ID not found')),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            gradient: LinearGradient(
                                              colors: [Colors.deepPurpleAccent, Colors.purpleAccent.shade100],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.quiz, color: Colors.white, size: 32),
                                              SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Take Quiz',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Get personalized course ',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
                  ),
                );
              }
          ),

          // Decoration effects overlay
          if (selectedDecoration != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildDecorationEffect(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffect() {
    switch (selectedBackground) {
      case 'background_aurora':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.withOpacity(0.7),
                Colors.purple.withOpacity(0.7),
                Colors.blue.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );

      case 'background_cityscape':
        return Stack(
          children: [
            Container(color: Colors.black87),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: CustomPaint(
                painter: CityscapePainter(),
              ),
            ),
            _buildCityLights(),
          ],
        );

      case 'background_space':
        return Stack(
          children: [
            Container(color: Colors.black),
            _buildStars(),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    Colors.deepPurple.withOpacity(0.5),
                    Colors.indigo.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  radius: 1.0,
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDecorationEffect() {
    switch (selectedDecoration) {
      case 'decoration_confetti':
        return ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: -pi / 2,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          maxBlastForce: 5,
          minBlastForce: 2,
          gravity: 0.1,
          shouldLoop: true,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ],
        );

      case 'decoration_flames':
        return AnimatedFlames();

      case 'decoration_bubbles':
        return BubbleAnimation(
          numberOfBubbles: 15,
          maxBubbleSize: 20,
          minBubbleSize: 8,
          bubbleColor: Colors.lightBlueAccent.withOpacity(0.3),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileImage(User? profile) {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Profile image
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              ),
            )
          else if (profile?.avatar != null && profile!.avatar!.isNotEmpty)
            if (profile.avatar!.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: CachedNetworkImage(
                  imageUrl: CloudinaryConstants.getProfileImageUrl(profile.avatar!),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultAvatar(),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/${profile.avatar}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                ),
              )
          else
            _buildDefaultAvatar(),
          // Frame effect
          if (selectedFrame != null)
            _buildFrameEffect(),
        ],
      ),
    );
  }

  Widget _buildFrameEffect() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 3,
          color: selectedFrame == 'frame_rainbow'
              ? HSVColor.fromAHSV(1.0, (DateTime.now().millisecondsSinceEpoch / 10) % 360, 1.0, 1.0).toColor()
              : selectedFrame == 'frame_galaxy'
              ? Colors.indigo
              : Colors.greenAccent,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedFrame == 'frame_rainbow'
                ? HSVColor.fromAHSV(1.0, (DateTime.now().millisecondsSinceEpoch / 10) % 360, 1.0, 0.8).toColor().withOpacity(0.5)
                : selectedFrame == 'frame_galaxy'
                ? Colors.indigo.withOpacity(0.5)
                : Colors.greenAccent.withOpacity(_pulseValue ? 0.6 : 0.3),
            blurRadius: _pulseValue ? 15 : 5,
            spreadRadius: _pulseValue ? 3 : 1,
          ),
        ],
      ),
    );
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

  Widget _buildCityLights() {
    return Stack(
      children: List.generate(
        30,
            (index) => Positioned(
          left: Random().nextDouble() * MediaQuery.of(context).size.width,
          bottom: Random().nextDouble() * 100,
          child: Container(
            width: 2,
            height: Random().nextDouble() * 10 + 5,
            color: Colors.yellow.withOpacity(Random().nextDouble() * 0.8 + 0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Stack(
      children: List.generate(
        50,
            (index) => Positioned(
          left: Random().nextDouble() * MediaQuery.of(context).size.width,
          top: Random().nextDouble() * MediaQuery.of(context).size.height,
          child: Icon(
            Icons.star,
            size: Random().nextDouble() * 3 + 1,
            color: Colors.white.withOpacity(Random().nextDouble() * 0.8 + 0.2),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEquippedCosmetics();
  }
}

class CityscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Draw random buildings
    double x = 0;
    while (x < size.width) {
      final buildingHeight = Random().nextDouble() * 60 + 20;
      final buildingWidth = Random().nextDouble() * 30 + 10;

      path.lineTo(x, size.height - buildingHeight);
      path.lineTo(x + buildingWidth, size.height - buildingHeight);
      path.lineTo(x + buildingWidth, size.height);

      x += buildingWidth;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedFlames extends StatefulWidget {
  @override
  State<AnimatedFlames> createState() => _AnimatedFlamesState();
}

class _AnimatedFlamesState extends State<AnimatedFlames> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<int> _seeds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _seeds = List.generate(10, (_) => Random().nextInt(100000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final flames = List.generate(
      10,
          (i) {
        final rand = Random(_seeds[i]);
        return Flame(
          x: rand.nextDouble() * width,
          y: rand.nextDouble() * height,
          size: rand.nextDouble() * 20 + 10,
        );
      },
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: flames.map((flame) {
            final progress = _controller.value;
            final y = flame.y - (progress * 50);
            final opacity = 1 - progress;
            return Positioned(
              left: flame.x,
              top: y,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.local_fire_department,
                  size: flame.size,
                  color: Colors.orange,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class Flame {
  final double x;
  final double y;
  final double size;

  Flame({required this.x, required this.y, required this.size});
}

class BubbleAnimation extends StatefulWidget {
  final int numberOfBubbles;
  final double maxBubbleSize;
  final double minBubbleSize;
  final Color bubbleColor;

  const BubbleAnimation({
    Key? key,
    required this.numberOfBubbles,
    required this.maxBubbleSize,
    required this.minBubbleSize,
    required this.bubbleColor,
  }) : super(key: key);

  @override
  State<BubbleAnimation> createState() => _BubbleAnimationState();
}

class _BubbleAnimationState extends State<BubbleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<int> _seeds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _seeds = List.generate(widget.numberOfBubbles, (_) => Random().nextInt(100000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final bubbles = List.generate(
      widget.numberOfBubbles,
          (i) {
        final rand = Random(_seeds[i]);
        return Bubble(
          x: rand.nextDouble() * width,
          y: height,
          size: rand.nextDouble() * (widget.maxBubbleSize - widget.minBubbleSize) + widget.minBubbleSize,
          speed: rand.nextDouble() * 2 + 1,
        );
      },
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: bubbles.map((bubble) {
            final progress = _controller.value;
            final y = bubble.y - (progress * bubble.speed * height);
            return Positioned(
              left: bubble.x,
              top: y,
              child: Container(
                width: bubble.size,
                height: bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bubbleColor,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class Bubble {
  final double x;
  final double y;
  final double size;
  final double speed;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}