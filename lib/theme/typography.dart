/// CodeOps text styles.
///
/// Uses Inter as the primary font family with JetBrains Mono for code.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

/// Centralized text style definitions for the CodeOps theme.
class CodeOpsTypography {
  CodeOpsTypography._();

  /// Primary font family.
  static const String fontFamily = 'Inter';

  /// Monospace font family for code display.
  static const String codeFontFamily = 'JetBrains Mono';

  /// Fallback monospace font families.
  static const List<String> codeFontFallback = ['Fira Code', 'monospace'];

  /// Headline large — 32px bold.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: CodeOpsColors.textPrimary,
    height: 1.25,
  );

  /// Headline medium — 28px semi-bold.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: CodeOpsColors.textPrimary,
    height: 1.29,
  );

  /// Headline small — 24px semi-bold.
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: CodeOpsColors.textPrimary,
    height: 1.33,
  );

  /// Title large — 20px semi-bold.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CodeOpsColors.textPrimary,
    height: 1.4,
  );

  /// Title medium — 16px semi-bold.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CodeOpsColors.textPrimary,
    height: 1.5,
  );

  /// Title small — 14px semi-bold.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CodeOpsColors.textPrimary,
    height: 1.43,
  );

  /// Body large — 16px regular.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CodeOpsColors.textPrimary,
    height: 1.5,
  );

  /// Body medium — 14px regular.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CodeOpsColors.textPrimary,
    height: 1.43,
  );

  /// Body small — 12px regular.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CodeOpsColors.textSecondary,
    height: 1.33,
  );

  /// Label large — 14px medium.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CodeOpsColors.textPrimary,
    height: 1.43,
  );

  /// Label medium — 12px medium.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: CodeOpsColors.textSecondary,
    height: 1.33,
  );

  /// Label small — 11px medium.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: CodeOpsColors.textTertiary,
    height: 1.45,
  );

  /// Monospace style for code display — 13px regular.
  static const TextStyle code = TextStyle(
    fontFamily: codeFontFamily,
    fontFamilyFallback: codeFontFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: CodeOpsColors.textPrimary,
    height: 1.54,
  );
}
