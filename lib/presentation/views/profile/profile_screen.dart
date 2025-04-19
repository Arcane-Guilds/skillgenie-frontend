import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:skillGenie/data/models/community/post.dart';

import '../../../data/models/user_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../../core/constants/cloudinary_constants.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../community/post_detail_screen.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../community/update_post_screen.dart';
import '../community/create_post_screen.dart';

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
      // Show error message in UI instead of just logging
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

    // Check authentication
    if (!authViewModel.isAuthenticated) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!authViewModel.isAuthenticated) {
        context.go('/login');
        return;
      }
    }

    // Load profile
    final profile = await profileViewModel.getUserProfile(forceRefresh: true);
    if (!mounted) return;

    if (profile == null) {
      _showErrorSnackBar('Could not load profile data');
      return;
    }

    // Load posts immediately after profile
    await _loadUserPosts(profile.id); // Ensure this is awaited

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
                      Theme.of(context).colorScheme.primary,
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
                child: const Text('Cancel'),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future _saveBio() async {
    if (_bioController.text
        .trim()
        .isEmpty) {
      _showErrorSnackBar('Bio cannot be empty');
      return;
    }

    try {
      final profileViewModel = Provider.of<ProfileViewModel>(
          context, listen: false);
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
          return const Center(child: CircularProgressIndicator());
        }
        
        if (communityViewModel.userPostsStatus == CommunityStatus.error) {
          return Column(
            children: [
              Text(communityViewModel.errorMessage ?? 'Error loading posts'),
              ElevatedButton(
                onPressed: () => _loadUserPosts(profileViewModel.currentProfile!.id),
                child: const Text('Retry'),
              ),
            ],
          );
        }

        // Show "Create First Post" button if user has no posts
        if (communityViewModel.userPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.post_add,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You haven\'t created any posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Post'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => _navigateToPostDetail(post.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: post.author.avatar != null
                                ? NetworkImage(post.author.avatar!)
                                : null,
                            child: post.author.avatar == null
                                ? const Icon(Icons.person)
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
                                  _formatDate(post.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Add 3-dots menu for post actions
                          if (post.author.id == Provider.of<AuthViewModel>(context, listen: false).user?.id)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
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
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit Post'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete Post'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (post.images != null && post.images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.images!.length,
                            itemBuilder: (context, imageIndex) {
                              // Transform the image URL using Cloudinary
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
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              final communityViewModel = Provider.of<CommunityViewModel>(context, listen: false);
                              communityViewModel.togglePostLike(post.id);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: post.isLiked ? Theme.of(context).colorScheme.error : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.likeCount.toString(),
                                    style: TextStyle(
                                      color: post.isLiked ? Theme.of(context).colorScheme.error : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => _navigateToPostDetail(post.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.commentCount.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
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
                ),
              ),
            );
          },
        );
      },
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final communityViewModel = Provider.of<CommunityViewModel>(context, listen: false);
                await communityViewModel.deletePost(postId);
                
                if (mounted) {
                  // Remove the post from the UI immediately
                  setState(() {
                    // Remove from user posts list
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
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              GoRouter.of(context).go('/friends');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Consumer2<AuthViewModel, ProfileViewModel>(
        builder: (context, authViewModel, profileViewModel, _) {
          // Show loading while checking auth or loading profile
          if (!authViewModel.isAuthenticated || profileViewModel.isLoading || _isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }


          return RefreshIndicator(
            onRefresh: () async {
              // Load both profile and posts on refresh
              await _loadInitialData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'My Posts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUserPosts(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User? profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
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
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: _buildProfileImage(profile),
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
                    color: Theme
                        .of(context)
                        .colorScheme
                        .secondary,
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
          Text(
            profile?.username ?? 'User Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isEditingBio = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isEditingBio
                  ? Column(
                children: [
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write something about yourself...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isEditingBio = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _saveBio,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        profile?.bio?.isNotEmpty == true
                            ? profile!.bio!
                            : 'Tap to add bio...',
                        style: TextStyle(
                          color: profile?.bio?.isNotEmpty == true
                              ? Colors.grey[100]
                              : Colors.grey[100],
                        ),
                      ),
                    ),
                  ),
                  //const Icon(Icons.edit, size: 16),
                ],
              ),
            ),
          )
        ],
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
      // Check if the avatar is a Cloudinary URL
      if (profile.avatar!.startsWith('http')) {
        // Apply Cloudinary transformations for optimized delivery
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
        // Fallback to local asset if not a URL
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
}