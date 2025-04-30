import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/core/theme/app_theme.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../../core/errors/error_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFormKey = GlobalKey<FormState>();
  final _bioFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
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
                          _showErrorSnackBar('Failed to update password: $e');
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
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
                  setState(() => _isLoading = true);
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
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
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
                  setState(() => _isLoading = true);
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
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
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

  void _showEditProfileDialog() {
    final usernameController =
        TextEditingController(text: _usernameController.text);
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
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: tempImageFile != null
                            ? FileImage(tempImageFile)
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: tempImageFile == null
                            ? const Icon(Icons.person,
                                size: 48, color: Colors.grey)
                            : null,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 18,
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      final profileViewModel =
                          Provider.of<ProfileViewModel>(context, listen: false);
                      try {
                        if (tempImageFile != null) {
                          await profileViewModel
                              .updateProfileImage(tempImageFile);
                        }
                        await profileViewModel
                            .updateUsername(usernameController.text.trim());
                        await profileViewModel
                            .updateBio(bioController.text.trim());
                        setState(() {
                          _usernameController.text =
                              usernameController.text.trim();
                          _bioController.text = bioController.text.trim();
                        });
                        _showSuccessSnackBar('Profile updated successfully!');
                      } catch (e) {
                        _showErrorSnackBar('Failed to update profile: $e');
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
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
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (user?.avatar != null &&
                                          user!.avatar!.isNotEmpty
                                      ? NetworkImage(user.avatar!)
                                      : null) as ImageProvider<Object>?,
                              backgroundColor: Colors.grey[200],
                              child: _imageFile == null &&
                                      (user?.avatar == null ||
                                          user!.avatar!.isEmpty)
                                  ? const Icon(Icons.person,
                                      size: 40, color: Colors.grey)
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
                            onPressed: _showEditProfileDialog,
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
                          const Icon(Icons.password, color: AppTheme.primaryColor),
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
                          child: const Icon(Icons.notifications_active,
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
                ],
              ),
            ),
    );
  }
}
