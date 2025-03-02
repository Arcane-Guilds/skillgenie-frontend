import 'dart:async';
import 'dart:io';

import '../../data/models/api_exception.dart';

/// General application error types
enum AppErrorType {
  network,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  server,
  timeout,
  unknown
}

/// Application error model
class AppError {
  final AppErrorType type;
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError{type: $type, message: $message, details: $details}';
}

/// Central error handler for the application
class ErrorHandler {
  /// Transform any exception into a standardized AppError
  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    // API exceptions
    if (error is ApiException) {
      return _handleApiException(error, stackTrace);
    }

    // Network errors
    if (error is SocketException || error is TimeoutException) {
      return AppError(
        type: AppErrorType.network,
        message: 'Network connection error. Please check your internet connection.',
        details: error.toString(),
        stackTrace: stackTrace,
      );
    }

    // Default unknown error
    return AppError(
      type: AppErrorType.unknown,
      message: 'An unexpected error occurred.',
      details: error.toString(),
      stackTrace: stackTrace,
    );
  }

  /// Handle API-specific exceptions
  static AppError _handleApiException(ApiException exception, [StackTrace? stackTrace]) {
    switch (exception.statusCode) {
      case 400:
        return AppError(
          type: AppErrorType.badRequest,
          message: 'Invalid request. Please check your inputs.',
          details: exception.message,
          stackTrace: stackTrace,
        );
      case 401:
        return AppError(
          type: AppErrorType.unauthorized,
          message: 'Unauthorized. Please log in again.',
          details: exception.message,
          stackTrace: stackTrace,
        );
      case 403:
        return AppError(
          type: AppErrorType.forbidden,
          message: 'You do not have permission to access this resource.',
          details: exception.message,
          stackTrace: stackTrace,
        );
      case 404:
        return AppError(
          type: AppErrorType.notFound,
          message: 'The requested resource was not found.',
          details: exception.message,
          stackTrace: stackTrace,
        );
      case 500:
      case 502:
      case 503:
        return AppError(
          type: AppErrorType.server,
          message: 'Server error. Please try again later.',
          details: exception.message,
          stackTrace: stackTrace,
        );
      default:
        return AppError(
          type: AppErrorType.unknown,
          message: 'An error occurred while communicating with the server.',
          details: exception.message,
          stackTrace: stackTrace,
        );
    }
  }

  /// Return user-friendly error message based on error type
  static String getUserFriendlyErrorMessage(AppError error) {
    switch (error.type) {
      case AppErrorType.network:
        return 'No internet connection. Please check your network settings.';
      case AppErrorType.unauthorized:
        return 'Session expired. Please log in again.';
      case AppErrorType.server:
        return 'Our servers are currently experiencing issues. Please try again later.';
      case AppErrorType.timeout:
        return 'The request timed out. Please try again.';
      default:
        return error.message;
    }
  }
}