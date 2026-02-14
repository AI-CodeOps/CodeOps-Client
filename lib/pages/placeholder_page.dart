/// Temporary placeholder page displayed for routes whose full implementation
/// is delivered in a later COC task.
///
/// Shows the page title and current route path so navigation can be verified.
library;

import 'package:flutter/material.dart';

import 'package:codeops/theme/colors.dart';

/// A reusable placeholder for routes not yet implemented.
class PlaceholderPage extends StatelessWidget {
  /// The page title displayed prominently in the center.
  final String title;

  /// Creates a [PlaceholderPage] for the given [title].
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final path = ModalRoute.of(context)?.settings.name;

    return Scaffold(
      backgroundColor: CodeOpsColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path ?? 'Coming soon',
              style: const TextStyle(
                fontSize: 14,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
