/// Confirmation dialog for manually triggering a secret rotation.
///
/// Displays the secret name and path, warns about the operation,
/// and provides Confirm / Cancel actions.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A confirmation dialog for manual secret rotation.
class VaultManualRotateDialog extends StatelessWidget {
  /// Display name of the secret being rotated.
  final String secretName;

  /// Hierarchical path of the secret.
  final String secretPath;

  /// Creates a [VaultManualRotateDialog].
  const VaultManualRotateDialog({
    super.key,
    required this.secretName,
    required this.secretPath,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Rotate Secret'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to manually rotate this secret?',
              style: TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeOpsColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CodeOpsColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    secretName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secretPath,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CodeOpsColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: CodeOpsColors.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will generate a new secret value and increment '
                      'the version. The previous value will remain accessible '
                      'until it is destroyed.',
                      style: TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.warning,
            foregroundColor: Colors.black,
          ),
          child: const Text('Rotate Now'),
        ),
      ],
    );
  }
}
