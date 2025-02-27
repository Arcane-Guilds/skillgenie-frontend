import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10), // Timeout for connection
    receiveTimeout: const Duration(seconds: 10), // Timeout for receiving data
  ));

  /// Fetches data from the API using a GET request.
  Future<Response> getData(String endpoint) async {
    try {
      Response response = await _dio.get(endpoint);
      return response;
    } catch (e) {
      throw Exception("GET Request Error: $e");
    }
  }

  /// Sends a POST request to the API.
  Future<Response> postRequest(String url, Map<String, dynamic> data) async {
    try {
      Response response = await _dio.post(url, data: data);
      return response;
    } catch (e) {
      throw Exception("POST Request Error: $e");
    }
  }

  /// Sends a PUT request to the API.
  Future<Response> putRequest(String url, Map<String, dynamic> data) async {
    try {
      Response response = await _dio.put(url, data: data);
      return response;
    } catch (e) {
      throw Exception("PUT Request Error: $e");
    }
  }

  /// Sends a PATCH request to the API.
  Future<Response> patchRequest(String url, Map<String, dynamic> data) async {
    try {
      Response response = await _dio.patch(url, data: data);
      return response;
    } catch (e) {
      throw Exception("PATCH Request Error: $e");
    }
  }

  /// Sends a DELETE request to the API.
  Future<Response> deleteRequest(String url) async {
    try {
      Response response = await _dio.delete(url);
      return response;
    } catch (e) {
      throw Exception("DELETE Request Error: $e");
    }
  }

  /// Adds an authentication token to the headers of the Dio instance.
  void addAuthenticationToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes the authentication token from the headers of the Dio instance.
  void removeAuthenticationToken() {
    _dio.options.headers.remove('Authorization');
  }
}