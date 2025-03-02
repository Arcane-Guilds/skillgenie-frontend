import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/user_model.dart';
import 'auth_viewmodel.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final AuthViewModel _authViewModel;

  User? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  bool _isCacheValid = false;
  static const cacheDuration = Duration(minutes: 5);

  DateTime? _lastApiCallTime;
  static const apiCallDebounceTime = Duration(seconds: 2);

  ProfileViewModel({
    required ProfileRepository profileRepository,
    required AuthViewModel authViewModel,
  })  : _profileRepository = profileRepository,
        _authViewModel = authViewModel {
    // Initialize profile data when viewmodel is created
    _initializeProfile();
  }

  // Getters
  User? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCacheValid => _isCacheValid && _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < cacheDuration;

  bool get canMakeApiCall => _lastApiCallTime == null ||
      DateTime.now().difference(_lastApiCallTime!) > apiCallDebounceTime;

  // Initialize profile
  Future<void> _initializeProfile() async {
    if (_authViewModel.isAuthenticated) {
      await getUserProfile();
    }
  }

  // Get user profile with caching
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid && _currentProfile != null) {
      return _currentProfile!;
    }

    // Prevent rapid successive API calls
    if (!canMakeApiCall) {
      return _currentProfile ?? (throw Exception('Profile not available'));
    }

    _isLoading = true;
    _errorMessage = null;
    _lastApiCallTime = DateTime.now();
    notifyListeners();

    try {
      final profile = await _profileRepository.getUserProfile(forceRefresh: forceRefresh);
      _currentProfile = profile;
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      return profile;
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
      _isCacheValid = false;
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update bio with optimistic updates
  Future<void> updateBio(String newBio) async {
    if (_currentProfile == null) return;

    final previousProfile = _currentProfile;

    try {
      // Optimistic update
      _currentProfile = _currentProfile!.copyWith(bio: newBio);
      notifyListeners();

      await _profileRepository.updateUserProfile(_currentProfile!);
      _isCacheValid = true;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      // Rollback on failure
      _currentProfile = previousProfile;
      _errorMessage = 'Failed to update bio: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // Update profile image with progress tracking
  Future<void> updateProfileImage(File newProfileImage) async {
    if (_currentProfile == null) return;

    final previousProfile = _currentProfile;

    try {
      _isLoading = true;
      notifyListeners();

      // Upload the new image
      final avatar = await _profileRepository.uploadProfileImage(newProfileImage);

      if (avatar != null) {
        // Update the profile with the new image URL
        _currentProfile = _currentProfile!.copyWith(avatar: avatar);
        await _profileRepository.updateUserProfile(_currentProfile!);
        _isCacheValid = true;
        _lastFetchTime = DateTime.now();
      }
    } catch (e) {
      // Rollback on failure
      _currentProfile = previousProfile;
      _errorMessage = 'Failed to update profile image: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update password with proper error handling
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First verify the current password is correct
      await _profileRepository.updatePassword(currentPassword, newPassword);

      // Password updated successfully, refresh the auth state
      // This prevents the black screen issue by ensuring tokens are still valid
      await _authViewModel.checkAuthStatus();

      // Invalidate cache after password change but don't force a refresh yet
      _isCacheValid = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update password: ${e.toString()}';
      notifyListeners();
      throw e;
    }
  }

  // Logout with cleanup
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear profile cache first
      await _profileRepository.clearCache();

      // Then sign out from auth
      await _authViewModel.signOut();

      // Clear local state
      _currentProfile = null;
      _isCacheValid = false;
      _lastFetchTime = null;
    } catch (e) {
      _errorMessage = 'Failed to logout: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete account with proper cleanup
  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Delete the profile first
      await _profileRepository.deleteUserProfile();

      // Clear profile cache
      await _profileRepository.clearCache();

      // Then sign out from auth
      await _authViewModel.signOut();

      // Clear all local state
      _currentProfile = null;
      _isCacheValid = false;
      _lastFetchTime = null;
    } catch (e) {
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Invalidate cache
  void invalidateCache() {
    _isCacheValid = false;
    notifyListeners();
  }
}
