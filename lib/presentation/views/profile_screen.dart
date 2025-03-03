import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../core/widgets/app_error_widget.dart';
import '../../data/models/user_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../core/errors/error_handler.dart';
import '../../core/constants/cloudinary_constants.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _initControllers() {
    _bioController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    final profileViewModel = Provider.of<ProfileViewModel>(
        context, listen: false);
    try {
      await profileViewModel.getUserProfile(forceRefresh: true);
      if (mounted) {
        _bioController.text = profileViewModel.currentProfile?.bio ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load profile. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message, {VoidCallback? onRetry}) {
    final error = AppError(
        type: AppErrorType.unknown,
        message: message
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getUserFriendlyErrorMessage(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null ? SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ) : null,
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

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        final userProfile = profileViewModel.currentProfile;
        final isLoading = profileViewModel.isLoading;
        final errorMessage = profileViewModel.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _navigateToSettings,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                profileViewModel.getUserProfile(forceRefresh: true),
            child: isLoading && userProfile == null
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null && userProfile == null
                ? AppErrorWidget(
              error: AppError(
                type: AppErrorType.unknown,
                message: errorMessage,
              ),
              onRetry: _loadUserProfile,
            )
                : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(userProfile),
                ],
              ),
            ),
          ),
        );
      },
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
            Theme
                .of(context)
                .colorScheme
                .primary,
            Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.7),
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