import 'package:flutter/material.dart';
import '../../core/errors/error_handler.dart';

/// A reusable widget for displaying errors with retry functionality
class AppErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final bool showDetails;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              _getIconForErrorType(error.type),
              size: 64,
              color: _getColorForErrorType(error.type),
            ),
            const SizedBox(height: 16),

            // Error message
            Text(
              ErrorHandler.getUserFriendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            // Error details (optional)
            if (showDetails && error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],

            // Retry button (optional)
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get the appropriate icon for the error type
  IconData _getIconForErrorType(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.unauthorized:
        return Icons.lock;
      case AppErrorType.server:
        return Icons.cloud_off;
      case AppErrorType.timeout:
        return Icons.timer_off;
      case AppErrorType.notFound:
        return Icons.find_replace;
      case AppErrorType.badRequest:
        return Icons.error_outline;
      case AppErrorType.forbidden:
        return Icons.block;
      default:
        return Icons.error;
    }
  }

  /// Get the appropriate color for the error type
  Color _getColorForErrorType(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Colors.orange;
      case AppErrorType.unauthorized:
        return Colors.red.shade700;
      case AppErrorType.server:
        return Colors.purple.shade700;
      case AppErrorType.timeout:
        return Colors.amber.shade700;
      case AppErrorType.notFound:
        return Colors.grey.shade700;
      default:
        return Colors.red;
    }
  }
}