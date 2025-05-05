import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../models/api_exception.dart';
import '../../core/constants/api_constants.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger = Logger('ApiClient');

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15), // Increased timeout
          receiveTimeout: const Duration(seconds: 15), // Increased timeout
          contentType: 'application/json', // Set content-type header
          validateStatus: (status) {
            // Allow the Dio client to return responses with any status code
            // so we can handle errors manually
            return true;
          },
        )) {
    // Add pretty logger interceptor for better request/response logging
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
    ));

    // Configure SSL bypass for development
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        // ⚠️ WARNING: This bypasses SSL certificate validation
        // TODO: Remove in production
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
      _logger.warning('SSL certificate validation disabled for development');
    }
  }

  /// Fetches data from the API using a GET request.
  Future<Response> getData(String endpoint) async {
    try {
      _logger.info('GET request to: $endpoint');
      Response response = await _dio.get(
        endpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      _logger.info('GET response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      _logger.severe('Dio error during GET request: $e');
      throw _handleDioError(e);
    } catch (e) {
      _logger.severe('Error during GET request: $e');
      throw ApiException(
        'Network error occurred',
        500,
        e.toString(),
      );
    }
  }

  /// Sends a POST request to the API.
  Future<Response> postRequest(String url, Map<String, dynamic> data) async {
    try {
      _logger.info('POST request to: $url with data: $data');
      Response response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          method: 'POST', // Explicitly set method
        ),
      );
      _logger.info('POST response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      _logger.severe('Dio error during POST request: $e');
      throw _handleDioError(e);
    } catch (e) {
      _logger.severe('Error during POST request: $e');
      throw ApiException(
        'Network error occurred',
        500,
        e.toString(),
      );
    }
  }

  /// Sends a PUT request to the API.
  Future<Response> putRequest(String url, Map<String, dynamic> data) async {
    try {
      _logger.info('PUT request to: $url');
      Response response = await _dio.put(url, data: data);
      _logger.info('PUT response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      _logger.severe('Dio error during PUT request: $e');
      throw _handleDioError(e);
    } catch (e) {
      _logger.severe('Error during PUT request: $e');
      throw ApiException(
        'Network error occurred',
        500,
        e.toString(),
      );
    }
  }

  /// Sends a PATCH request to the API.
  Future<Response> patchRequest(String url, Map<String, dynamic> data) async {
    try {
      _logger.info('PATCH request to: $url');
      Response response = await _dio.patch(url, data: data);
      _logger.info('PATCH response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      _logger.severe('Dio error during PATCH request: $e');
      throw _handleDioError(e);
    } catch (e) {
      _logger.severe('Error during PATCH request: $e');
      throw ApiException(
        'Network error occurred',
        500,
        e.toString(),
      );
    }
  }

  /// Sends a DELETE request to the API.
  Future<Response> deleteRequest(String url) async {
    try {
      _logger.info('DELETE request to: $url');
      Response response = await _dio.delete(url);
      _logger.info('DELETE response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      _logger.severe('Dio error during DELETE request: $e');
      throw _handleDioError(e);
    } catch (e) {
      _logger.severe('Error during DELETE request: $e');
      throw ApiException(
        'Network error occurred',
        500,
        e.toString(),
      );
    }
  }

  /// Adds an authentication token to the headers of the Dio instance.
  void addAuthenticationToken(String token) {
    _logger.info('Adding authentication token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes the authentication token from the headers of the Dio instance.
  void removeAuthenticationToken() {
    _logger.info('Removing authentication token');
    _dio.options.headers.remove('Authorization');
  }

  /// Helper method to handle Dio errors
  ApiException _handleDioError(DioException error) {
    int statusCode = error.response?.statusCode ?? 500;
    String message;

    switch (statusCode) {
      case 400:
        message = 'Bad request';
        break;
      case 401:
        message = 'Your session has expired. Please log in again.';
        break;
      case 403:
        message = 'Access forbidden';
        break;
      case 404:
        message = 'Resource not found';
        break;
      case 500:
        message = 'Server error';
        break;
      default:
        message = 'Network error occurred';
    }

    String details =
        error.response?.data?.toString() ?? error.message ?? 'Unknown error';

    return ApiException(message, statusCode, details);
  }
}
