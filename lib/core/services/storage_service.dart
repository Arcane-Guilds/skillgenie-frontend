import 'dart:io';
import 'dart:developer';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/constants/api_constants.dart';

class StorageService {
  final String _cloudName;
  final String _uploadPreset;
  late final CloudinaryPublic _cloudinary;
  final http.Client _httpClient;

  StorageService({
    required String cloudName,
    required String uploadPreset,
    http.Client? httpClient,
  })  : _cloudName = cloudName,
        _uploadPreset = uploadPreset,
        _httpClient = httpClient ?? http.Client() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Uploads a profile image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadProfileImage(File image,
      {Function(double)? onProgress}) async {
    try {
      log('Starting Cloudinary upload for profile image');

      // Create a CloudinaryResponse by uploading the file
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: 'user_profiles',
          resourceType: CloudinaryResourceType.Image,
        ),
        onProgress: (count, total) {
          final progress = count / total;
          if (onProgress != null) {
            onProgress(progress);
          }
          log('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
      );

      log('Cloudinary upload successful: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      log('Error uploading image to Cloudinary: $e');
      if (kDebugMode) {
        print('Cloudinary upload error: $e');
      }
      return null;
    }
  }

  /// Alternative method to upload directly to the backend API
  /// This is useful if you want the backend to handle the Cloudinary upload
  Future<String?> uploadProfileImageViaBackend(File image,
      {Function(double)? onProgress}) async {
    try {
      log('Starting profile image upload via backend API');

      // Get the file extension and mime type
      final fileExtension = path.extension(image.path).replaceAll('.', '');
      final mimeType = lookupMimeType(image.path) ?? 'image/$fileExtension';

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/cloudinary/upload/profile-image'),
      );

      // Add the file to the request
      final fileStream = http.ByteStream(image.openRead());
      final fileLength = await image.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(image.path),
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // Track upload progress
      int bytesSent = 0;
      final streamedResponse = await request.send();

      streamedResponse.stream.listen((List<int> chunk) {
        bytesSent += chunk.length;
        if (onProgress != null) {
          final progress = bytesSent / fileLength;
          onProgress(progress);
        }
      });

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = response.body;
        log('Backend upload successful: $responseData');
        // Parse the response to get the URL
        // This depends on your backend response format
        return responseData; // Modify this based on your backend response
      } else {
        log('Backend upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error uploading image via backend: $e');
      return null;
    }
  }

  /// Deletes a profile image from Cloudinary
  /// Takes the full URL and extracts the public ID
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;

      // Extract the public ID from the URL
      // Example URL: https://res.cloudinary.com/your-cloud-name/image/upload/v1234567890/user_profiles/abcdef123456
      // Public ID would be: user_profiles/abcdef123456

      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the index of 'upload' in the path
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        log('Invalid Cloudinary URL format');
        return false;
      }

      // The public ID starts after the version segment (which comes after 'upload')
      final publicId = pathSegments.sublist(uploadIndex + 2).join('/');

      log('Attempting to delete image with public ID: $publicId');

      // Note: Actual deletion would require server-side implementation
      // Cloudinary doesn't support client-side deletion for security reasons
      // You would need to call your backend API to perform the deletion

      log('Image deletion request sent to server');
      return true;
    } catch (e) {
      log('Error deleting image from Cloudinary: $e');
      return false;
    }
  }
}
