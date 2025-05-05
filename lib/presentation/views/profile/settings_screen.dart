import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/core/theme/app_theme.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';
import '../../../data/models/user_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/reminder_viewmodel.dart';
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
  final _usernameFormKey = GlobalKey<FormState>();
  final _bioFormKey = GlobalKey<FormState>();
  File? _imageFile;
  bool _isUploadingImage = false;
  double _uploadProgress = 0;

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
      if (mounted && profile != null) {
        setState(() {
          _usernameController.text = profile.username;
          _bioController.text = profile.bio ?? '';
        });
      } else if (mounted && profileViewModel.errorMessage != null) {
        _showErrorSnackBar(profileViewModel.errorMessage!);
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

  Widget _buildReminderCard(BuildContext context) {
    final reminderVM = Provider.of<ReminderViewModel>(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Reminder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reminderVM.reminderTime != null
                            ? reminderVM.reminderTime!.format(context)
                            : 'Not set',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminderVM.remindersEnabled,
                  onChanged: (value) async {
                    if (value && reminderVM.reminderTime == null) {
                      _showReminderTimePicker(context);
                      return;
                    }
                    await reminderVM.toggleReminders(value);
                  },
                ),
              ],
            ),
            if (reminderVM.remindersEnabled)
              TextButton(
                onPressed: () => _showReminderTimePicker(context),
                child: const Text('Change Time'),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    bool hasMinLength = false;
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumber = false;
    bool hasSpecialChar = false;
    bool passwordsMatch = false;

    // Store a global navigatorKey for safer navigation
    final navigatorKey = GlobalKey<NavigatorState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            void validatePassword(String password) {
              setState(() {
                hasMinLength = password.length >= 8;
                hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
                hasLowercase = RegExp(r'[a-z]').hasMatch(password);
                hasNumber = RegExp(r'[0-9]').hasMatch(password);
                hasSpecialChar = RegExp(r'[!@#\$&*~?=]').hasMatch(password);
                passwordsMatch = password == confirmPasswordController.text;
              });
            }

            void checkPasswordsMatch(String confirmPassword) {
              setState(() {
                passwordsMatch = confirmPassword == newPasswordController.text;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: AppTheme.primaryColor),
                  SizedBox(width: 10),
                  Text('Change Password'),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter current password'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        onChanged: validatePassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.password),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter new password';
                          }
                          if (!hasMinLength) return 'At least 8 characters';
                          if (!hasUppercase) {
                            return 'At least one uppercase letter';
                          }
                          if (!hasLowercase) {
                            return 'At least one lowercase letter';
                          }
                          if (!hasNumber) return 'At least one number';
                          if (!hasSpecialChar) {
                            return 'At least one special character';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequirementRow(
                                hasMinLength, 'At least 8 characters'),
                            _buildRequirementRow(
                                hasUppercase, 'At least one uppercase letter'),
                            _buildRequirementRow(
                                hasLowercase, 'At least one lowercase letter'),
                            _buildRequirementRow(
                                hasNumber, 'At least one number'),
                            _buildRequirementRow(hasSpecialChar,
                                'At least one special character'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        onChanged: checkPasswordsMatch,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.check_circle_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // 1. Store necessary data locally to avoid widget references
                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;

                      // 2. Close dialog first to avoid UI issues
                      Navigator.of(dialogContext).pop();

                      // 3. Get a stable BuildContext reference from the current screen
                      final stableContext = context;

                      // 4. Helper function to show a message on the stable context
                      void showMessage(String message, bool isError) {
                        if (!mounted) return;

                        final snackBar = SnackBar(
                          content: Text(message),
                          backgroundColor: isError ? Colors.red : Colors.green,
                          behavior: SnackBarBehavior.floating,
                        );

                        ScaffoldMessenger.of(stableContext).showSnackBar(snackBar);
                      }

                      try {
                        // 5. Show a loading dialog using the stable context
                        showDialog(
                          context: stableContext,
                          barrierDismissible: false,
                          builder: (loadingContext) => const AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Updating password...'),
                              ],
                            ),
                          ),
                        );

                        // 6. Get ProfileViewModel without using BuildContext
                        final profileViewModel = Provider.of<ProfileViewModel>(
                            stableContext,
                            listen: false);

                        // 7. Execute the password change
                        await profileViewModel.updatePassword(
                          currentPassword,
                          newPassword,
                        );

                        // 8. Password change was successful
                        if (mounted) {
                          // 9. Close the loading dialog (if still shown)
                          Navigator.of(stableContext).pop();

                          // 10. Show success message
                          showMessage('Password updated successfully! Please log in again.', false);

                          // 11. Navigate directly without delay
                          // By using WidgetsBinding we trigger navigation in the next frame
                          // after the current UI update completes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              // Navigate to login screen
                              GoRouter.of(stableContext).go('/login');
                            }
                          });
                        }
                      } catch (e) {
                        // 12. Handle error
                        if (mounted) {
                          // Close the loading dialog if it's showing
                          Navigator.of(stableContext).pop();

                          // Log error for debugging
                          print('Error during password change: $e');

                          // Extract meaningful error message
                          final errorMessage = e.toString().contains('401')
                              ? 'Current password is incorrect.'
                              : e.toString().contains('503')
                                  ? 'Server is currently unavailable. Please try again later.'
                                  : 'Failed to update password: $e';

                          showMessage(errorMessage, true);
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
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
                final profileViewModel =
                    Provider.of<ProfileViewModel>(context, listen: false);
                await profileViewModel.logout();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog FIRST

              final profileViewModel = context.read<ProfileViewModel>();
              final stableContext = context; // Store context

              try {
                await profileViewModel.deleteAccount();

                // If deleteAccount succeeds, pop the loading dialog.
                if (stableContext.mounted) {
                   Navigator.of(stableContext).pop(); // Pop loading dialog
                }

              } catch (e) {
                // Pop loading dialog on error
                if (stableContext.mounted) {
                  Navigator.of(stableContext).pop();
                }

                // Show error message
                if (stableContext.mounted) {
                  ScaffoldMessenger.of(stableContext).showSnackBar(
                    SnackBar(
                      content: Text(profileViewModel.errorMessage?? 'Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                          final profileViewModel =
                              Provider.of<ProfileViewModel>(context,
                                  listen: false);

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
                            _showSuccessSnackBar(
                                'Profile picture updated successfully!');
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            _showErrorSnackBar(
                                'Failed to update profile picture: ${e.toString()}');
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

  void _showUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Update Username'),
          ],
        ),
        content: Form(
          key: _usernameFormKey,
          child: TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Username must be at least 3 characters',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (value.length > 30) {
                return 'Username must be less than 30 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(value)) {
                return 'Username can only contain letters, numbers, underscores, and hyphens';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_usernameFormKey.currentState!.validate()) {
                Navigator.pop(context);
                try {
                  final profileViewModel =
                      Provider.of<ProfileViewModel>(context, listen: false);
                  await profileViewModel
                      .updateUsername(_usernameController.text.trim());
                  if (mounted) {
                    _showSuccessSnackBar('Username updated successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar(
                        'Failed to update username: ${e.toString()}');
                  }
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showBioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Update Bio'),
          ],
        ),
        content: Form(
          key: _bioFormKey,
          child: TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText: 'Tell us about yourself',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a bio';
              }
              if (value.length > 150) {
                return 'Bio must be less than 150 characters';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_bioFormKey.currentState!.validate()) {
                Navigator.pop(context);
                try {
                  final profileViewModel =
                      Provider.of<ProfileViewModel>(context, listen: false);
                  await profileViewModel.updateBio(_bioController.text.trim());
                  if (mounted) {
                    _showSuccessSnackBar('Bio updated successfully!');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Failed to update bio: ${e.toString()}');
                  }
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }


  void _showEditProfileDialog(User user) {
    final usernameController = TextEditingController(text: _usernameController.text);
    final bioController = TextEditingController(text: _bioController.text);
    File? tempImageFile = _imageFile;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: tempImageFile != null
                            ? FileImage(tempImageFile)
                            : _imageFile != null
                                ? FileImage(_imageFile!)
                                : user.avatar != null && user.avatar!.isNotEmpty
                                    ? (user.avatar!.startsWith('http')
                                        ? NetworkImage(user.avatar ?? '')
                                        : AssetImage('assets/images/${user.avatar}.png'))
                                    : null,
                        backgroundColor: Colors.grey[200],
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 18,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (value.length > 30) {
                      return 'Username must be less than 30 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, underscores, and hyphens';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 150) {
                      return 'Bio must be less than 150 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validate inputs
                      if (usernameController.text.trim().isEmpty) {
                        _showErrorSnackBar('Username cannot be empty');
                        return;
                      }

                      Navigator.pop(context);

                      try {
                        final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
                        String? imageUrl;

                        // First, handle image upload if needed
                        if (tempImageFile != null) {
                          try {
                            // Keep local image uploading state
                            setState(() => _isUploadingImage = true);
                            imageUrl = await profileViewModel.uploadProfileImageAndGetUrl(tempImageFile);
                          } catch (e) {
                            if (mounted) {
                               setState(() => _isUploadingImage = false); // Reset image specific state
                               _showErrorSnackBar('Failed to upload image: $e');
                            }
                            return;
                          } finally {
                             if (mounted) {
                               setState(() => _isUploadingImage = false); // Reset image specific state
                             }
                          }
                        }

                        // Now update the profile with all the data
                        final updateData = {
                          'username': usernameController.text.trim(),
                          'bio': bioController.text.trim(),
                        };

                        // Only add avatar if we have a new image URL
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          updateData['avatar'] = imageUrl;
                        }

                        // Send direct update with validated data
                        await profileViewModel.updateProfile(updateData);

                        // Update local state after successful profile update
                        if (mounted) {
                           setState(() {
                             _usernameController.text = usernameController.text.trim();
                             _bioController.text = bioController.text.trim();
                             _imageFile = tempImageFile; // Update screen's _imageFile if temp was used
                           });
                           _showSuccessSnackBar('Profile updated successfully!');
                        }
                      } catch (e) {
                         if (mounted) {
                            _showErrorSnackBar('Failed to update profile: $e');
                         }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final profileViewModel = Provider.of<ProfileViewModel>(context);
    final user = profileViewModel.currentProfile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white), // Make sure the title is also white
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // <-- This sets the back button color
      ),

      body: profileViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genie Avatar
                  const Center(
                    child: GenieAvatar(
                      state: AvatarState.idle,
                      size: 100,
                      message: "Manage your profile & preferences!",
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Profile Card
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : user?.avatar != null && user!.avatar!.isNotEmpty
                                      ? (user.avatar!.startsWith('http')
                                          ? NetworkImage(user.avatar!)
                                          : AssetImage('assets/images/${user.avatar}.png'))
                                      : null,
                              child: _imageFile == null &&
                                  (user?.avatar == null || user!.avatar!.isEmpty)
                                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                  : null,
                            ),
                          ),

                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _usernameController.text,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _bioController.text.isNotEmpty
                                      ? _bioController.text
                                      : "No bio set.",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditProfileDialog(user!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Section: Security
                  const Text('Security',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    child: ListTile(
                      leading:
                          Icon(Icons.password, color: AppTheme.primaryColor),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showChangePasswordDialog,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section: Reminders
                  const Text('Reminders',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Consumer<ReminderViewModel>(
                    builder: (context, reminderVM, _) => Card(
                      color: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.notifications_active,
                              color: AppTheme.primaryColor, size: 28),
                        ),
                        title: const Text('Daily Reminder',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          reminderVM.remindersEnabled
                              ? 'Set for ${reminderVM.formattedTime}'
                              : 'No reminder set',
                          style: TextStyle(
                            color: reminderVM.remindersEnabled
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Switch(
                          value: reminderVM.remindersEnabled,
                          onChanged: (value) async {
                            if (value && reminderVM.reminderTime == null) {
                              _showReminderTimePicker(context);
                              return;
                            }
                            await reminderVM.toggleReminders(value);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        onTap: reminderVM.remindersEnabled
                            ? () => _showReminderTimePicker(context)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Support',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Reclamation Button
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.report_problem_outlined,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      title: const Text('Submit Reclamation',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                        'Report issues or submit feedback',
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.go('/reclamation'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Section: Account Actions
                  const Text('Account Actions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text('Logout'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showLogoutConfirmation,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    child: ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account',
                          style: TextStyle(color: Colors.red)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showDeleteAccountConfirmation,
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
}
