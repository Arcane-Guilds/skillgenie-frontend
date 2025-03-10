import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_constants.dart';

class CloudinaryConstants {
  // Replace these with your actual Cloudinary credentials
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dfevpedux';
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'preset-for-file-upload';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '589553953838916'; // Optional, for signed uploads

  // API endpoints
  static String get baseApiUrl => ApiConstants.baseUrl;
  static String get uploadEndpoint => '$baseApiUrl/cloudinary/upload/profile-image';
  static String get deleteEndpoint => '$baseApiUrl/cloudinary/delete/profile-image';

  // Folder structure
  static const String userProfilesFolder = 'user_profiles';

  // Transformations
  static const String profileImageTransformation = 'c_fill,g_face,w_400,h_400';
  static const String thumbnailTransformation = 'c_thumb,g_face,w_150,h_150';
  static const String highQualityTransformation = 'q_auto:best';

  // Helper method to get a transformed URL
  static String getProfileImageUrl(String originalUrl) {
    if (originalUrl.isEmpty || !originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Find the upload part in the URL
    final uploadIndex = originalUrl.indexOf('/upload/');
    if (uploadIndex == -1) return originalUrl;

    // Insert transformation after /upload/
    return originalUrl.substring(0, uploadIndex + 8) +
        profileImageTransformation +
        originalUrl.substring(uploadIndex + 7);
  }

  // Helper method to get a thumbnail URL
  static String getThumbnailUrl(String originalUrl) {
    if (originalUrl.isEmpty || !originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Find the upload part in the URL
    final uploadIndex = originalUrl.indexOf('/upload/');
    if (uploadIndex == -1) return originalUrl;

    // Insert transformation after /upload/
    return originalUrl.substring(0, uploadIndex + 8) +
        thumbnailTransformation +
        originalUrl.substring(uploadIndex + 7);
  }

  // Helper method to extract public ID from Cloudinary URL
  static String? extractPublicId(String url) {
    try {
      if (url.isEmpty || !url.contains('cloudinary.com')) {
        return null;
      }

      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the index of 'upload' in the path
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // The public ID starts after the version segment (which comes after 'upload')
      final publicIdWithVersion = pathSegments.sublist(uploadIndex + 1).join('/');

      // Remove the version part (v1234567890/)
      final publicId = publicIdWithVersion.replaceFirst(RegExp(r'^v\d+\/'), '');

      return publicId;
    } catch (e) {
      return null;
    }
  }
}