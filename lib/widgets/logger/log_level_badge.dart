/// Reusable log level badge with color coding.
///
/// Displays a log level as either a compact colored dot or a full
/// text badge. Color mapping uses [CodeOpsColors] for consistency.
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../theme/colors.dart';

/// A colored badge that represents a [LogLevel].
///
/// Supports two display modes:
/// - **compact**: Small colored dot (8×8) — useful in dense lists.
/// - **full**: Rounded label with colored background and text.
class LogLevelBadge extends StatelessWidget {
  /// The log level to display.
  final LogLevel level;

  /// Whether to show the compact dot variant.
  ///
  /// Defaults to `false` (full text badge).
  final bool compact;

  /// Creates a [LogLevelBadge].
  const LogLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  /// Returns the display color for the given [level].
  static Color colorForLevel(LogLevel level) {
    return switch (level) {
      LogLevel.fatal => CodeOpsColors.critical,
      LogLevel.error => CodeOpsColors.error,
      LogLevel.warn => CodeOpsColors.warning,
      LogLevel.info => CodeOpsColors.secondary,
      LogLevel.debug => CodeOpsColors.textSecondary,
      LogLevel.trace => CodeOpsColors.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForLevel(level);

    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level.displayName.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
