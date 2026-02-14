/// Centered error display with icon, title, message, and optional retry.
///
/// Provides a [fromException] factory that maps [ApiException] subtypes
/// to user-friendly messages.
library;

import 'package:flutter/material.dart';

import '../../services/cloud/api_exceptions.dart';
import '../../theme/colors.dart';

/// A centered error panel with icon, title, message, and optional retry.
class ErrorPanel extends StatelessWidget {
  /// Title displayed below the error icon.
  final String title;

  /// Detailed error message.
  final String message;

  /// Callback invoked when the retry button is tapped.
  final VoidCallback? onRetry;

  /// Creates an [ErrorPanel].
  const ErrorPanel({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  /// Maps an [ApiException] subtype to a user-friendly [ErrorPanel].
  factory ErrorPanel.fromException(Object error, {VoidCallback? onRetry}) {
    final (title, message) = switch (error) {
      NetworkException() => ('No Internet', 'Check your network connection and try again.'),
      TimeoutException() => ('Request Timed Out', 'The server took too long to respond.'),
      ServerException() => ('Server Error', 'Something went wrong on the server.'),
      UnauthorizedException() => ('Session Expired', 'Please log in again to continue.'),
      ForbiddenException() => ('Access Denied', 'You do not have permission for this action.'),
      _ => ('Something Went Wrong', 'An unexpected error occurred.'),
    };
    return ErrorPanel(title: title, message: message, onRetry: onRetry);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: CodeOpsColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
