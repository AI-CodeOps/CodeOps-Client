// Tests for AppTheme.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/theme/colors.dart';

void main() {
  group('AppTheme', () {
    test('darkTheme is not null', () {
      expect(AppTheme.darkTheme, isNotNull);
    });

    test('brightness is dark', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('primary color matches CodeOpsColors.primary', () {
      expect(AppTheme.darkTheme.colorScheme.primary, CodeOpsColors.primary);
    });

    test('scaffold background is CodeOpsColors.background', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          CodeOpsColors.background);
    });

    test('card theme has border', () {
      expect(AppTheme.darkTheme.cardTheme.color, CodeOpsColors.surface);
    });
  });
}
