/// Full-screen loading overlay with optional message.
///
/// Covers the parent with a semi-transparent barrier and centered
/// progress indicator. Uses [AbsorbPointer] to block interaction.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A semi-transparent overlay with a centered loading indicator.
class LoadingOverlay extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Creates a [LoadingOverlay] with an optional [message].
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: CodeOpsColors.primary,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
