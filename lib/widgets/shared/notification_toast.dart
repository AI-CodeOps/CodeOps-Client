/// Notification toast displayed via ScaffoldMessenger.
///
/// Provides a [showToast] function and [ToastType] enum for typed messages.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Type of toast notification determining icon and color.
enum ToastType {
  /// Success toast (green).
  success,

  /// Informational toast (blue).
  info,

  /// Warning toast (amber).
  warning,

  /// Error toast (red).
  error,
}

/// Shows a floating toast notification at the bottom of the screen.
void showToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final (icon, color) = switch (type) {
    ToastType.success => (Icons.check_circle_outline, CodeOpsColors.success),
    ToastType.info => (Icons.info_outline, CodeOpsColors.secondary),
    ToastType.warning => (Icons.warning_amber_outlined, CodeOpsColors.warning),
    ToastType.error => (Icons.error_outline, CodeOpsColors.error),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: NotificationToast(message: message, icon: icon, color: color),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      width: 500,
    ),
  );
}

/// The visual content of a toast notification.
class NotificationToast extends StatelessWidget {
  /// Message text.
  final String message;

  /// Leading icon.
  final IconData icon;

  /// Accent color for icon and left border.
  final Color color;

  /// Creates a [NotificationToast].
  const NotificationToast({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
