import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../core/services/profile_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/user_model.dart';
import 'auth_viewmodel.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;
  final StorageService _storageService;
  final AuthViewModel _authViewModel; // Added AuthViewModel as a dependency

  User? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileViewModel({
    required ProfileService profileService,
    required StorageService storageService,
    required AuthViewModel authViewModel, // Inject AuthViewModel
  })  : _profileService = profileService,
        _storageService = storageService,
        _authViewModel = authViewModel;

  // Getters
  User? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods
  Future<User> getUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final profile = await _profileService.fetchUserProfile();
      _currentProfile = profile; // Store the profile
      notifyListeners(); // Notify listeners about the change
      return profile;
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBio(String newBio) async {
    if (_currentProfile == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedProfile = _currentProfile!.copyWith(bio: newBio);
      await _profileService.updateUserProfile(updatedProfile);
      _currentProfile = updatedProfile;
    } catch (e) {
      _errorMessage = 'Failed to update bio: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _profileService.updatePassword(currentPassword, newPassword);
    } catch (e) {
      _errorMessage = 'Failed to update password: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(File? newProfileImage) async {
    if (newProfileImage == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Upload the new image
      final avatar = await _storageService.uploadProfileImage(newProfileImage);
      // Update the profile with the new image URL
      final updatedProfile = _currentProfile!.copyWith(avatar: avatar);
      await _profileService.updateUserProfile(updatedProfile);
      // Update local state
      _currentProfile = updatedProfile;
    } catch (e) {
      _errorMessage = 'Failed to update profile image: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Call the signout method from AuthViewModel
      await _authViewModel.signOut();
      _currentProfile = null; // Clear the current profile
    } catch (e) {
      _errorMessage = 'Failed to logout: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileService.deleteUserProfile();
      _currentProfile = null;
    } catch (e) {
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfilePhoto() async {
    if (_currentProfile?.avatar == null || _currentProfile?.avatar?.isEmpty == true) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      // Delete the photo from storage
      await _storageService.deleteProfileImage(_currentProfile!.avatar ?? '');
      // Update profile with empty photo URL
      final updatedProfile = _currentProfile!.copyWith(avatar: '');
      await _profileService.updateUserProfile(updatedProfile);
      // Update local state
      _currentProfile = updatedProfile;
    } catch (e) {
      _errorMessage = 'Failed to delete profile photo: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}