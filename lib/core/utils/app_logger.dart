import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging utility for the application
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    // Only log in debug mode
    level: kDebugMode ? Level.verbose : Level.error,
  );

  static final Logger _productionLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: false,
      printEmojis: false,
      printTime: true,
    ),
    level: Level.error,
  );

  /// Log information
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      _logger.i('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log debug information
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      _logger.d('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log warnings
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      _logger.w('${tag != null ? '[$tag] ' : ''}$message');
    } else {
      _productionLogger.w('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log errors

  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final Logger logger = kDebugMode ? _logger : _productionLogger;
    logger.e(
      '${tag != null ? '[$tag] ' : ''}$message',
      error,
      stackTrace,
    );
  }

  /// Log analytics events
  static void analytics(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      _logger.i('[Analytics] $eventName${parameters != null ? ' - $parameters' : ''}');
    }

    // Here you would typically log to your analytics service
    // For example: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
  }
}