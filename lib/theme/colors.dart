/// CodeOps color palette.
///
/// Professional dark theme colors designed for a developer tool.
/// Severity and status colors provide consistent visual feedback.
library;

import 'dart:ui';

import 'package:codeops/models/enums.dart';

/// Centralized color definitions for the CodeOps dark theme.
class CodeOpsColors {
  CodeOpsColors._();

  /// Deep navy background.
  static const Color background = Color(0xFF1A1B2E);

  /// Card and panel background.
  static const Color surface = Color(0xFF222442);

  /// Elevated surface variant.
  static const Color surfaceVariant = Color(0xFF2A2D52);

  /// Primary indigo/purple accent.
  static const Color primary = Color(0xFF6C63FF);

  /// Darker primary variant.
  static const Color primaryVariant = Color(0xFF5A52D5);

  /// Cyan secondary accent.
  static const Color secondary = Color(0xFF00D9FF);

  /// Success green.
  static const Color success = Color(0xFF4ADE80);

  /// Warning amber.
  static const Color warning = Color(0xFFFBBF24);

  /// Error red.
  static const Color error = Color(0xFFEF4444);

  /// Deeper red for CRITICAL severity.
  static const Color critical = Color(0xFFDC2626);

  /// Primary text — near white.
  static const Color textPrimary = Color(0xFFE2E8F0);

  /// Secondary text — grey.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Tertiary text — dim grey.
  static const Color textTertiary = Color(0xFF64748B);

  /// Subtle border color.
  static const Color border = Color(0xFF334155);

  /// Divider color.
  static const Color divider = Color(0xFF1E293B);

  /// Maps each [Severity] to its corresponding color.
  static const Map<Severity, Color> severityColors = {
    Severity.critical: critical,
    Severity.high: error,
    Severity.medium: warning,
    Severity.low: secondary,
  };

  /// Maps each [JobStatus] to its corresponding color.
  static const Map<JobStatus, Color> jobStatusColors = {
    JobStatus.pending: textTertiary,
    JobStatus.running: primary,
    JobStatus.completed: success,
    JobStatus.failed: error,
    JobStatus.cancelled: textTertiary,
  };
}
