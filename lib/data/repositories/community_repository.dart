import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/community/post.dart';
import '../models/community/comment.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/community_constants.dart';

class CommunityRepository {
  final http.Client client;

  CommunityRepository({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> getAllPosts(String token) async {
    try {
      final url = '${ApiConstants.baseUrl}/${CommunityConstants.allPosts}';
      print('Requesting posts from: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          // Parse the response body with error handling
          final String responseBody = response.body;
          if (responseBody.isEmpty) {
            print('Empty response body');
            return {'posts': []};
          }
          
          final data = json.decode(responseBody) as Map<String, dynamic>;
          print('Response data preview: ${data.toString().substring(0, min(100, data.toString().length))}...');
          
          // Ensure the 'posts' field exists and is a List
          if (!data.containsKey('posts')) {
            print('Response does not contain posts field');
            return {'posts': []};
          }
          
          if (data['posts'] is! List) {
            print('Posts field is not a List: ${data['posts'].runtimeType}');
            return {'posts': []};
          }
          
          return data;
        } catch (parseError) {
          print('Error parsing response: $parseError');
          return {'posts': []};
        }
      } else {
        print('Server error: ${response.body}');
        return {'posts': []};
      }
    } catch (e) {
      print('Error in getAllPosts: $e');
      // Return empty data structure instead of throwing to prevent app crashes
      return {'posts': []};
    }
  }

  Future<Post> getPostById(String token, String postId) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.postById}/$postId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Post.fromJson(data);
    } else {
      throw Exception('Failed to load post: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCommentsForPost(
    String token,
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/community/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'comments': data,
          'total': data.length,
          'hasMore': false // No more pagination with the new API
        };
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getCommentsForPost: $e');
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<Post> createPost(String token, String content, List<String> imagePaths, {String? title}) async {
    try {
      final url = '${ApiConstants.baseUrl}/${CommunityConstants.posts}';
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add content and title
      request.fields['content'] = content;
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }
      
      // Add images
      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images', imagePath),
          );
        }
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        return Post.fromJson(data);
      } else {
        throw Exception('Failed to create post: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error in createPost: $e');
      rethrow;
    }
  }

  Future<Comment> createComment(
    String token,
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final requestData = {
      'postId': postId,
      'content': content,
    };

    if (parentCommentId != null) {
      requestData['parentCommentId'] = parentCommentId;
    }

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.comments}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestData),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Comment.fromJson(data);
    } else {
      throw Exception('Failed to create comment: ${response.statusCode}');
    }
  }

  Future<Comment> replyToComment(
    String token,
    String postId,
    String commentId,
    String content,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.replyToComment}/$commentId/reply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'postId': postId,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Comment.fromJson(data);
    } else {
      throw Exception('Failed to reply to comment: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> likePost(String token, String postId) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.likes}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'postId': postId,
          'type': 'post',
        }),
      );

      print('Like post response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': true, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': true};
        }
      } else {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in likePost: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  Future<Map<String, dynamic>> unlikePost(String token, String postId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.likes}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'postId': postId,
          'type': 'post',
        }),
      );

      print('Unlike post response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': false, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': false};
        }
      } else {
        throw Exception('Failed to unlike post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in unlikePost: $e');
      throw Exception('Failed to unlike post: $e');
    }
  }

  Future<Map<String, dynamic>> likeComment(String token, String commentId) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.likes}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'commentId': commentId,
          'type': 'comment',
        }),
      );

      print('Like comment response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': true, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': true};
        }
      } else {
        throw Exception('Failed to like comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in likeComment: $e');
      throw Exception('Failed to like comment: $e');
    }
  }

  Future<Map<String, dynamic>> unlikeComment(String token, String commentId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.likes}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'commentId': commentId,
          'type': 'comment',
        }),
      );

      print('Unlike comment response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': false, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': false};
        }
      } else {
        throw Exception('Failed to unlike comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in unlikeComment: $e');
      throw Exception('Failed to unlike comment: $e');
    }
  }

  Future<void> deletePost(String token, String postId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.postById}/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print('Error deleting post: Status code ${response.statusCode}, Response: ${response.body}');
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in deletePost: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> deleteComment(String token, String commentId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/${CommunityConstants.comments}/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print('Error deleting comment: Status code ${response.statusCode}, Response: ${response.body}');
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in deleteComment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<Map<String, dynamic>> likeReply(String token, String replyId) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/community/replies/$replyId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Like reply response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': true, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': true};
        }
      } else {
        throw Exception('Failed to like reply: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in likeReply: $e');
      throw Exception('Failed to like reply: $e');
    }
  }

  Future<Map<String, dynamic>> unlikeReply(String token, String replyId) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/community/replies/$replyId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Unlike reply response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return {'isLiked': false, ...data};
        } catch (e) {
          // If can't parse response, still return success
          return {'isLiked': false};
        }
      } else {
        throw Exception('Failed to unlike reply: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in unlikeReply: $e');
      throw Exception('Failed to unlike reply: $e');
    }
  }

  Future<Map<String, dynamic>> getUserPosts(String token, String userId) async {
    try {
      final url = '${ApiConstants.baseUrl}/community/posts/user/$userId';
      print('Requesting user posts from: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final String responseBody = response.body;
          if (responseBody.isEmpty) {
            print('Empty response body');
            return {'posts': [], 'total': 0};
          }
          
          final data = json.decode(responseBody) as Map<String, dynamic>;
          print('Response data preview: ${data.toString().substring(0, min(100, data.toString().length))}...');
          
          if (!data.containsKey('posts')) {
            print('Response does not contain posts field');
            return {'posts': [], 'total': 0};
          }
          
          if (data['posts'] is! List) {
            print('Posts field is not a List: ${data['posts'].runtimeType}');
            return {'posts': [], 'total': 0};
          }
          
          return data;
        } catch (parseError) {
          print('Error parsing response: $parseError');
          return {'posts': [], 'total': 0};
        }
      } else {
        print('Server error: ${response.body}');
        return {'posts': [], 'total': 0};
      }
    } catch (e) {
      print('Error in getUserPosts: $e');
      return {'posts': [], 'total': 0};
    }
  }

  Future<Post> updatePost(String token, String postId, String content, String title, {List<String>? existingImages, List<File>? newImages}) async {
    try {
      // Create multipart request if we have new images
      if (newImages != null && newImages.isNotEmpty) {
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${ApiConstants.baseUrl}/community/posts/$postId'),
        );

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        // Add text fields
        request.fields['content'] = content;
        request.fields['title'] = title;
        
        // Add existing images if any
        if (existingImages != null) {
          request.fields['existingImages'] = json.encode(existingImages);
        }

        // Add new image files
        for (var i = 0; i < newImages.length; i++) {
          final file = newImages[i];
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              file.path,
              filename: 'image_${i + 1}.jpg',
            ),
          );
        }

        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return Post.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          print('Error updating post: $errorData');
          throw Exception('Failed to update post: ${response.statusCode} - ${errorData['message'] ?? errorData}');
        }
      } else {
        // No new images, use regular JSON request
        final response = await client.put(
          Uri.parse('${ApiConstants.baseUrl}/community/posts/$postId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'content': content,
            'title': title,
            'existingImages': existingImages,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return Post.fromJson(data);
        } else {
          final errorData = json.decode(response.body);
          print('Error updating post: $errorData');
          throw Exception('Failed to update post: ${response.statusCode} - ${errorData['message'] ?? errorData}');
        }
      }
    } catch (e) {
      print('Error in updatePost: $e');
      throw Exception('Failed to update post: $e');
    }
  }
} 