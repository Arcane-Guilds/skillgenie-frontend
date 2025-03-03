import 'api_constants.dart';

class CloudinaryConstants {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'dfevpedux';
  static const String uploadPreset = 'preset-for-file-upload';
  static const String apiKey = '589553953838916'; // Optional, for signed uploads

  // API endpoints
  static const String baseApiUrl = ApiConstants.baseUrl;
  static const String uploadEndpoint = '$baseApiUrl/cloudinary/upload/profile-image';
  static const String deleteEndpoint = '$baseApiUrl/cloudinary/delete/profile-image';

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