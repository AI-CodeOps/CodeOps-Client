/// Confirmation dialog with cancel/confirm actions.
///
/// Use the top-level [showConfirmDialog] function for convenient display.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Shows a [ConfirmDialog] and returns `true` (confirm), `false` (cancel),
/// or `null` (dismissed).
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
}

/// An [AlertDialog] with cancel and confirm actions.
class ConfirmDialog extends StatelessWidget {
  /// Dialog title.
  final String title;

  /// Dialog message body.
  final String message;

  /// Label for the confirm button.
  final String confirmLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Whether the confirm action is destructive (styles button red).
  final bool destructive;

  /// Creates a [ConfirmDialog].
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(title),
      content: Text(
        message,
        style: const TextStyle(color: CodeOpsColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
