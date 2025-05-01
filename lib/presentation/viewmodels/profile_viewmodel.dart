import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/api_exception.dart';
import 'auth/auth_viewmodel.dart';
import '../../data/repositories/achievement_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final AuthViewModel _authViewModel;
  final AchievementRepository _achievementRepository = AchievementRepository();

  User? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  bool _isCacheValid = false;
  static const cacheDuration = Duration(minutes: 5);

  DateTime? _lastApiCallTime;
  static const apiCallDebounceTime = Duration(seconds: 2);

  // Image upload state
  double _uploadProgress = 0;
  bool _isUploadingImage = false;

  int _badgeCount = 0;
  int get badgeCount => _badgeCount;

  ProfileViewModel({
    required ProfileRepository profileRepository,
    required AuthViewModel authViewModel,
  })  : _profileRepository = profileRepository,
        _authViewModel = authViewModel {
    // Listen to auth changes
    _authViewModel.addListener(_onAuthStateChanged);
  }

  // Add dispose to clean up listener
  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // Handle auth state changes
  void _onAuthStateChanged() {
    if (_authViewModel.isAuthenticated) {
      _initializeProfile();
    } else {
      // Clear profile data when logged out
      _currentProfile = null;
      _isCacheValid = false;
      notifyListeners();
    }
  }

  // Getters
  User? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isCacheValid => _isCacheValid && _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < cacheDuration;

  bool get canMakeApiCall => _lastApiCallTime == null ||
      DateTime.now().difference(_lastApiCallTime!) > apiCallDebounceTime;

  // Image upload getters
  double get uploadProgress => _uploadProgress;
  bool get isUploadingImage => _isUploadingImage;

  // Initialize profile
  Future<void> _initializeProfile() async {
    try {
      // Get profile with force refresh to ensure we have latest data
      await getUserProfile(forceRefresh: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Handle authentication errors
  Future<void> _handleAuthError() async {
    // Clear local profile data
    _currentProfile = null;
    _isCacheValid = false;
    
    // Log the user out to force re-authentication
    await _authViewModel.signOut();
    
    notifyListeners();
  }

  // Get user profile
  Future<User?> getUserProfile({bool forceRefresh = false}) async {
    if (!_authViewModel.isAuthenticated) {
      return null;
    }

    if (!forceRefresh && isCacheValid && _currentProfile != null) {
      return _currentProfile!;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _lastApiCallTime = DateTime.now();
      
      // Get fresh data from API
      final profile = await _profileRepository.getUserProfile(forceRefresh: true);
      _currentProfile = profile;
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      _setLoading(false);
      notifyListeners();
      return profile;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      
      // Only handle auth error if it's actually an auth error
      if (e is ApiException && e.statusCode == 401) {
        await _handleAuthError();
      }
      
      notifyListeners();
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(User updatedProfile) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      await _profileRepository.updateUserProfile(updatedProfile);
      _currentProfile = updatedProfile;
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Update bio
  Future<void> updateBio(String bio) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      await _profileRepository.updateBio(bio);
      
      // Update local model
      if (_currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(bio: bio);
      }
      
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Update username
  Future<void> updateUsername(String username) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      await _profileRepository.updateUsername(username);
      
      // Update local model
      if (_currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(username: username);
      }
      
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Update profile image
  Future<void> updateProfileImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastApiCallTime = DateTime.now();
      
      await _profileRepository.updateProfileImage(
        imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          onProgress?.call(progress);
          notifyListeners();
        },
      );
      
      // Refresh profile to get updated avatar URL
      await getUserProfile(forceRefresh: true);
      
      _isUploadingImage = false;
      _uploadProgress = 0;
      notifyListeners();
    } catch (e) {
      _isUploadingImage = false;
      _uploadProgress = 0;
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      notifyListeners();
      rethrow;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage() async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      final success = await _profileRepository.deleteProfileImage();
      
      if (success && _currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(avatar: '');
      }
      
      _lastFetchTime = DateTime.now();
      _isCacheValid = true;
      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      await _profileRepository.updatePassword(currentPassword, newPassword);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      await _profileRepository.deleteAccount();
      _currentProfile = null;
      _isCacheValid = false;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authViewModel.signOut();
      _currentProfile = null;
      _isCacheValid = false;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Retry profile fetch
  Future<void> retryProfileFetch() async {
    _errorMessage = null;
    try {
      await getUserProfile(forceRefresh: true);
    } catch (e) {
      // Error handling is done within getUserProfile
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset cache validity
  void invalidateCache() {
    _isCacheValid = false;
    notifyListeners();
  }

  Future<void> fetchUserBadgeCount() async {
    try {
      final count = await _achievementRepository.fetchUserBadgeCount(_authViewModel.user!.id);
      _badgeCount = count;
      notifyListeners();
    } catch (e) {
      // Optionally handle error
      _badgeCount = 0;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updateData, {String? username, String? bio, File? image}) async {
    if (!_authViewModel.isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _lastApiCallTime = DateTime.now();
      
      // Create a clean update data object with only the fields the backend expects
      final Map<String, dynamic> cleanUpdateData = {};
      
      // Handle profile fields
      if (username != null && username.isNotEmpty) {
        cleanUpdateData['username'] = username;
      } else if (updateData.containsKey('username')) {
        cleanUpdateData['username'] = updateData['username'];
      }
      
      if (bio != null) {
        cleanUpdateData['bio'] = bio;
      } else if (updateData.containsKey('bio')) {
        cleanUpdateData['bio'] = updateData['bio'];
      }
      
      if (updateData.containsKey('avatar')) {
        cleanUpdateData['avatar'] = updateData['avatar'];
      }
      
      // Make sure we have at least one field to update
      if (cleanUpdateData.isEmpty) {
        _setLoading(false);
        throw ApiException('No data to update', 400, 'Bad Request');
      }

      // Send the update to the API
      await _profileRepository.updateProfile(cleanUpdateData);
      
      // Refresh the profile data
      await getUserProfile(forceRefresh: true);
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      
      if (e is ApiException) {
        _errorMessage = e.message;
        
        // Handle authentication errors
        if (e.statusCode == 401) {
          await _handleAuthError();
        }
      } else {
        _errorMessage = e.toString();
      }
      
      rethrow;
    }
  }

  Future<String> uploadProfileImageAndGetUrl(File imageFile) async {
    // Use your storage service to upload and return the URL
    return await _profileRepository.uploadProfileImageAndGetUrl(imageFile);
  }
}