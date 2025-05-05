import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/viewmodels/reminder_viewmodel.dart';
import '../../../core/constants/cloudinary_constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/user_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/reclamation_viewmodel.dart';
import '../../../presentation/viewmodels/rating_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _imageFile;

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _initControllers();

    // Load user profile and reclamations on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      context.read<ReclamationViewModel>().loadReclamations();
    });
  }

  void _initControllers() {
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    final profileViewModel =
        Provider.of<ProfileViewModel>(context, listen: false);
    try {
      final profile = await profileViewModel.getUserProfile();
      if (mounted) {
        setState(() {
          _usernameController.text = profile!.username;
          _bioController.text = profile.bio ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load profile. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final error = AppError(
      type: AppErrorType.unknown,
      message: message,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getUserFriendlyErrorMessage(error)),
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

  // ================== Daily Reminder Section ==================
  void _showReminderTimePicker(BuildContext context) async {
    final reminderVM = Provider.of<ReminderViewModel>(context, listen: false);
    final initialTime =
        reminderVM.reminderTime ?? const TimeOfDay(hour: 20, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      await reminderVM.setReminderTime(pickedTime, true);
      if (mounted) {
        _showSuccessSnackBar(
            'Daily reminder set for ${pickedTime.format(context)}');
      }
    }
  }

  void _showChangePasswordDialog() {
    // Controllers for the password fields
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Variables to toggle password visibility
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    // Password validation states
    bool hasMinLength = false;
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumber = false;
    bool hasSpecialChar = false;
    bool passwordsMatch = false;

    // Create a StatefulBuilder to manage state within dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to validate password in real-time
            void validatePassword(String password) {
              setState(() {
                hasMinLength = password.length >= 8;
                hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
                hasLowercase = RegExp(r'[a-z]').hasMatch(password);
                hasNumber = RegExp(r'[0-9]').hasMatch(password);
                // Updated regex to include = and ? as special characters
                hasSpecialChar =
                    RegExp(r'[!@#$%^&*(),.?":{}|<>=+\-_]').hasMatch(password);

                // Check if passwords match
                if (confirmPasswordController.text.isNotEmpty) {
                  passwordsMatch = password == confirmPasswordController.text;
                }
              });
            }

            // Function to check if confirm password matches
            void checkPasswordsMatch(String confirmPassword) {
              setState(() {
                passwordsMatch = confirmPassword == newPasswordController.text;
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lock_reset,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('Change Password'),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: currentPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureCurrentPassword =
                                      !obscureCurrentPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: obscureCurrentPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.password),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            helperText: 'Password requirements:',
                            helperMaxLines: 2,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: obscureNewPassword,
                          onChanged: (value) {
                            validatePassword(value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter new password';
                            }
                            if (!hasMinLength) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!hasUppercase) {
                              return 'Password must contain at least one uppercase letter';
                            }
                            if (!hasLowercase) {
                              return 'Password must contain at least one lowercase letter';
                            }
                            if (!hasNumber) {
                              return 'Password must contain at least one number';
                            }
                            if (!hasSpecialChar) {
                              return 'Password must contain at least one special character';
                            }
                            return null;
                          },
                        ),

                        // Password requirements checklist
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequirementRow(
                                  hasMinLength, 'At least 8 characters'),
                              _buildRequirementRow(hasUppercase,
                                  'At least one uppercase letter'),
                              _buildRequirementRow(hasLowercase,
                                  'At least one lowercase letter'),
                              _buildRequirementRow(
                                  hasNumber, 'At least one number'),
                              _buildRequirementRow(hasSpecialChar,
                                  'At least one special character'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText:
                                confirmPasswordController.text.isNotEmpty &&
                                        !passwordsMatch
                                    ? 'Passwords do not match'
                                    : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: obscureConfirmPassword,
                          onChanged: checkPasswordsMatch,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        // Password match indicator
                        if (confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildRequirementRow(
                                passwordsMatch, 'Passwords match'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      // Show loading
                      setState(() => _isLoading = true);
                      try {
                        final profileViewModel = Provider.of<ProfileViewModel>(
                            context,
                            listen: false);
                        await profileViewModel.updatePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        if (mounted) {
                          _showSuccessSnackBar(
                              'Password updated successfully!');
                        }
                      } catch (e) {
                        if (mounted) {
                          _showErrorSnackBar(
                              'Failed to update password: ${e.toString()}');
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          },
        );
      },
    );
  }

  // Helper method to build password requirement row
  Widget _buildRequirementRow(bool isMet, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _isLoading = true);
                final profileViewModel =
                    Provider.of<ProfileViewModel>(context, listen: false);
                await profileViewModel.logout();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showErrorSnackBar('Failed to logout. Please try again.');
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Account'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• All your data will be permanently deleted',
              style: TextStyle(color: Colors.red),
            ),
            Text(
              '• This action cannot be undone',
              style: TextStyle(color: Colors.red),
            ),
            Text(
              '• You will be logged out immediately',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _isLoading = true);
                final profileViewModel =
                    Provider.of<ProfileViewModel>(context, listen: false);
                await profileViewModel.deleteAccount();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showErrorSnackBar(
                      'Failed to delete account. Please try again.');
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController usernameController =
        TextEditingController(text: _usernameController.text);
    final TextEditingController bioController =
        TextEditingController(text: _bioController.text);
    File? tempImageFile = _imageFile;
    bool isUploading = false;
    double progress = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.edit,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Profile Image
                    Consumer<ProfileViewModel>(
                      builder: (context, profileViewModel, _) {
                        final user = profileViewModel.currentProfile;
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1024,
                                    maxHeight: 1024,
                                    imageQuality: 95,
                                  );

                                  if (image != null) {
                                    setDialogState(() {
                                      tempImageFile = File(image.path);
                                    });
                                  }
                                } catch (e) {
                                  _showErrorSnackBar(
                                      'Failed to pick image. Please try again.');
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.5),
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: tempImageFile != null
                                          ? Image.file(
                                              tempImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : _buildProfileImage(user),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
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
                            ),
                            if (isUploading) ...[
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Username Field
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Username must be at least 3 characters',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bio Field
                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText:
                            'Tell us about yourself (max 150 characters)',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () async {
                                Navigator.pop(context);

                                setState(() => _isLoading = true);
                                final profileViewModel =
                                    Provider.of<ProfileViewModel>(context,
                                        listen: false);

                                try {
                                  // Update profile image if changed
                                  if (tempImageFile != null) {
                                    setDialogState(() {
                                      isUploading = true;
                                    });

                                    await profileViewModel.updateProfileImage(
                                      tempImageFile!,
                                      onProgress: (p) {
                                        setDialogState(() {
                                          progress = p;
                                        });
                                      },
                                    );
                                  }

                                  // Update username if changed
                                  if (usernameController.text !=
                                      _usernameController.text) {
                                    await profileViewModel.updateUsername(
                                        usernameController.text.trim());
                                    _usernameController.text =
                                        usernameController.text.trim();
                                  }

                                  // Update bio if changed
                                  if (bioController.text !=
                                      _bioController.text) {
                                    await profileViewModel
                                        .updateBio(bioController.text.trim());
                                    _bioController.text =
                                        bioController.text.trim();
                                  }

                                  if (mounted) {
                                    _showSuccessSnackBar(
                                        'Profile updated successfully!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showErrorSnackBar(
                                        'Failed to update profile: ${e.toString()}');
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                      _imageFile = null;
                                    });
                                  }
                                }
                              },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ReclamationViewModel>(
            builder: (context, viewModel, child) {
              final userId =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .currentProfile
                      ?.id;
              final unreadCount = viewModel.reclamations
                  .where((r) =>
                      r.user?.id == userId && r.adminResponse != null && !r.isRead)
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => context.go('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Edit Profile Card (New)
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showEditProfileDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Update your profile picture, username, and bio',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Section
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Password Card - Clickable to change password
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showChangePasswordDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.password,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Update your account password',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Add a new reminder card in the main settings screen after the "Change Password" card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showReminderTimePicker(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Consumer<ReminderViewModel>(
                                builder: (context, reminderVM, _) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daily Reminder',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        reminderVM.remindersEnabled
                                            ? 'Reminder set for ${reminderVM.formattedTime}'
                                            : 'Set a daily learning reminder',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Consumer<ReminderViewModel>(
                              builder: (context, reminderVM, _) {
                                return Switch(
                                  value: reminderVM.remindersEnabled,
                                  onChanged: (value) async {
                                    if (value &&
                                        reminderVM.reminderTime == null) {
                                      _showReminderTimePicker(context);
                                      return;
                                    }
                                    await reminderVM.toggleReminders(value);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Add Reclamation Button
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/reclamation'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.report_problem_outlined,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Submit Reclamation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Report issues or submit feedback',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Account Actions Section header
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Account Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Logout Button
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showLogoutConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Colors.orange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sign out from your account',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Delete Account Button
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _showDeleteAccountConfirmation,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Permanently delete your account and all data',
                                    style: TextStyle(
                                      color: Colors.red[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // App Rating Section
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'App Rating',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer<RatingViewModel>(
                      builder: (context, ratingVM, _) => ListTile(
                        leading: const Icon(Icons.star_outline),
                        title: const Text('App Ratings'),
                        subtitle: Text(
                          ratingVM.userRating != null
                              ? 'Your rating: ${ratingVM.userRating!.stars}/5'
                              : 'Rate our app',
                        ),
                        trailing: Text(
                          '${ratingVM.averageRating.toStringAsFixed(1)} ★',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => context.push('/ratings'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage(User? user) {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
      );
    }

    if (user?.avatar != null && user!.avatar!.isNotEmpty) {
      // Check if the avatar is a Cloudinary URL
      if (user.avatar!.startsWith('http')) {
        // Apply Cloudinary transformations for optimized delivery
        final transformedUrl =
            CloudinaryConstants.getThumbnailUrl(user.avatar!);

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
          'assets/images/${user.avatar}.png',
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
        size: 40,
        color: Colors.white,
      ),
    );
  }
}
