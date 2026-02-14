/// CodeOps application theme.
///
/// Builds a complete [ThemeData] from [CodeOpsColors] and [CodeOpsTypography].
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Provides the CodeOps [ThemeData] for the application.
class AppTheme {
  AppTheme._();

  /// The dark theme used by the CodeOps desktop app.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: CodeOpsTypography.fontFamily,
      scaffoldBackgroundColor: CodeOpsColors.background,
      colorScheme: const ColorScheme.dark(
        primary: CodeOpsColors.primary,
        onPrimary: Colors.white,
        secondary: CodeOpsColors.secondary,
        onSecondary: Colors.black,
        surface: CodeOpsColors.surface,
        onSurface: CodeOpsColors.textPrimary,
        error: CodeOpsColors.error,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: CodeOpsTypography.headlineLarge,
        headlineMedium: CodeOpsTypography.headlineMedium,
        headlineSmall: CodeOpsTypography.headlineSmall,
        titleLarge: CodeOpsTypography.titleLarge,
        titleMedium: CodeOpsTypography.titleMedium,
        titleSmall: CodeOpsTypography.titleSmall,
        bodyLarge: CodeOpsTypography.bodyLarge,
        bodyMedium: CodeOpsTypography.bodyMedium,
        bodySmall: CodeOpsTypography.bodySmall,
        labelLarge: CodeOpsTypography.labelLarge,
        labelMedium: CodeOpsTypography.labelMedium,
        labelSmall: CodeOpsTypography.labelSmall,
      ),
      cardTheme: const CardThemeData(
        color: CodeOpsColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: CodeOpsColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CodeOpsColors.background,
        foregroundColor: CodeOpsColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: CodeOpsTypography.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        hintStyle: CodeOpsTypography.bodyMedium
            .copyWith(color: CodeOpsColors.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CodeOpsColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: CodeOpsTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CodeOpsColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: CodeOpsColors.border),
          textStyle: CodeOpsTypography.labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CodeOpsColors.divider,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          CodeOpsColors.textTertiary.withValues(alpha: 0.3),
        ),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
