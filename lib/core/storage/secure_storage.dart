import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class SecureStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SharedPreferences _prefs;
  
  // Keys - updated to match the ones in AuthLocalDataSource
  static const String tokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userIdKey = 'user_id';
  
  SecureStorage(this._prefs);
  
  // Store JWT token
  Future<bool> setToken(String token) async {
    try {
      await _secureStorage.write(key: tokenKey, value: token);
      return true;
    } catch (e) {
      print('Error setting token in secure storage: $e');
      // Fall back to shared preferences
      try {
        await _prefs.setString(tokenKey, token);
        return true;
      } catch (e) {
        print('Error setting token in shared preferences: $e');
        return false;
      }
    }
  }
  
  // Get JWT token - first try secure storage, then fall back to shared prefs
  Future<String?> getToken() async {
    try {
      print('[SecureStorage] Attempting to get token');
      
      // Try secure storage first
      String? token = await _secureStorage.read(key: tokenKey);
      
      // If not found in secure storage, try shared prefs
      if (token == null || token.isEmpty) {
        print('[SecureStorage] Token not found in secure storage, checking SharedPreferences');
        token = _prefs.getString(tokenKey);
        
        if (token != null && token.isNotEmpty) {
          print('[SecureStorage] Found token in SharedPreferences: ${token.substring(0, math.min(10, token.length))}...');
          // Save it to secure storage for next time
          await _secureStorage.write(key: tokenKey, value: token);
        } else {
          // Try with a direct access
          print('[SecureStorage] Token not found in SharedPreferences either, checking all prefs keys');
          
          // Debug: list all keys in SharedPreferences
          final keys = _prefs.getKeys();
          print('[SecureStorage] All SharedPreferences keys: $keys');
          
          // Try with a direct instance
          final directPrefs = await SharedPreferences.getInstance();
          token = directPrefs.getString(tokenKey);
          
          if (token != null && token.isNotEmpty) {
            print('[SecureStorage] Found token via direct SharedPreferences instance');
            await _secureStorage.write(key: tokenKey, value: token);
          } else {
            print('[SecureStorage] Token not found in any storage location');
          }
        }
      } else {
        print('[SecureStorage] Found token in secure storage: ${token.substring(0, math.min(10, token.length))}...');
      }
      
      if (token == null) {
        print('[SecureStorage] WARNING: Returning null token');
      }
      
      return token;
    } catch (e) {
      print('[SecureStorage] Error retrieving token: $e');
      // Fall back to shared prefs in case of any secure storage issues
      final fallbackToken = _prefs.getString(tokenKey);
      if (fallbackToken != null) {
        print('[SecureStorage] Recovered token from fallback');
      }
      return fallbackToken;
    }
  }
  
  // Delete JWT token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: tokenKey);
    await _prefs.remove(tokenKey);
  }
  
  // Store user ID
  Future<void> setUserId(String userId) async {
    await _secureStorage.write(key: userIdKey, value: userId);
    // Also store in shared prefs for easier access
    await _prefs.setString(userIdKey, userId);
  }
  
  // Get user ID
  Future<String?> getUserId() async {
    print('[SecureStorage] Attempting to get userId');
    
    // Try secure storage first
    String? userId = await _secureStorage.read(key: userIdKey);
    if (userId != null && userId.isNotEmpty) {
      print('[SecureStorage] Found userId in secure storage: $userId');
      return userId;
    }
    
    // Fallback to shared prefs
    userId = _prefs.getString(userIdKey);
    if (userId != null && userId.isNotEmpty) {
      print('[SecureStorage] Found userId in shared preferences: $userId');
      // Save to secure storage for next time
      await _secureStorage.write(key: userIdKey, value: userId);
      return userId;
    }
    
    // If we still don't have a userId, try to extract it from the user object
    final userJson = _prefs.getString("user");
    if (userJson != null) {
      try {
        print('[SecureStorage] Attempting to extract userId from user JSON object');
        final Map<String, dynamic> userMap = json.decode(userJson);
        userId = userMap['id'] ?? userMap['_id'];
        if (userId != null) {
          print('[SecureStorage] Extracted userId from user object: $userId');
          // Save for next time
          await setUserId(userId);
          return userId;
        }
      } catch (e) {
        print('[SecureStorage] Error parsing user JSON: $e');
      }
    }
    
    // Last resort: try to extract user ID from the JWT token
    try {
      print('[SecureStorage] Attempting to extract userId from JWT token');
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        // JWT token is in the format: header.payload.signature
        final parts = token.split('.');
        if (parts.length == 3) {
          // Decode the payload (middle part)
          String normalizedPayload = parts[1];
          // Add padding if needed
          while (normalizedPayload.length % 4 != 0) {
            normalizedPayload += '=';
          }
          // Replace URL-safe characters
          normalizedPayload = normalizedPayload.replaceAll('-', '+').replaceAll('_', '/');
          
          final decodedBytes = base64Decode(normalizedPayload);
          final payloadJson = utf8.decode(decodedBytes);
          final payload = json.decode(payloadJson);
          
          // JWT usually has user ID as 'sub', 'id', '_id', or 'userId'
          userId = payload['_id'] ?? payload['id'] ?? payload['sub'] ?? payload['userId'];
          
          if (userId != null) {
            print('[SecureStorage] Extracted userId from JWT token: $userId');
            // Save it for future use
            await setUserId(userId);
            return userId;
          }
        }
      }
    } catch (e) {
      print('[SecureStorage] Error extracting userId from JWT: $e');
    }
    
    print('[SecureStorage] WARNING: Could not retrieve userId from any source');
    return null;
  }
  
  // Delete user ID
  Future<void> deleteUserId() async {
    await _secureStorage.delete(key: userIdKey);
    await _prefs.remove(userIdKey);
  }
  
  // Clear all secure storage data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    // Clear relevant prefs (but not all, as there might be other unrelated data)
    await _prefs.remove(userIdKey);
    await _prefs.remove(tokenKey);
    await _prefs.remove(refreshTokenKey);
  }
  
  /// Force sets the token in both secure storage and shared preferences
  /// with multiple verification attempts to ensure it's saved correctly.
  Future<bool> forceSetToken(String token) async {
    bool secureSuccess = false;
    bool prefsSuccess = false;
    
    // Try secure storage first
    try {
      await _secureStorage.write(key: tokenKey, value: token);
      
      // Verify it was saved
      final savedToken = await _secureStorage.read(key: tokenKey);
      secureSuccess = savedToken == token;
      
      if (secureSuccess) {
        print('Token successfully saved to secure storage');
      } else {
        print('WARNING: Token verification failed in secure storage');
      }
    } catch (e) {
      print('Error saving token to secure storage: $e');
    }
    
    // Always try shared preferences as backup
    try {
      await _prefs.setString(tokenKey, token);
      
      // Verify it was saved
      final savedToken = _prefs.getString(tokenKey);
      prefsSuccess = savedToken == token;
      
      if (prefsSuccess) {
        print('Token successfully saved to shared preferences');
      } else {
        print('WARNING: Token verification failed in shared preferences');
      }
    } catch (e) {
      print('Error saving token to shared preferences: $e');
    }
    
    // Return true if at least one method worked
    return secureSuccess || prefsSuccess;
  }
  
  /// Checks if any token exists in either secure storage or shared preferences
  Future<bool> hasAnyToken() async {
    try {
      final secureToken = await _secureStorage.read(key: tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        return true;
      }
    } catch (e) {
      print('Error checking token in secure storage: $e');
    }
    
    try {
      final prefToken = _prefs.getString(tokenKey);
      if (prefToken != null && prefToken.isNotEmpty) {
        return true;
      }
    } catch (e) {
      print('Error checking token in shared preferences: $e');
    }
    
    return false;
  }
} 