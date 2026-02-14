// Tests for CodeOpsColors.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/theme/colors.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('CodeOpsColors', () {
    test('all named colors are defined', () {
      expect(CodeOpsColors.background, isNotNull);
      expect(CodeOpsColors.surface, isNotNull);
      expect(CodeOpsColors.surfaceVariant, isNotNull);
      expect(CodeOpsColors.primary, isNotNull);
      expect(CodeOpsColors.primaryVariant, isNotNull);
      expect(CodeOpsColors.secondary, isNotNull);
      expect(CodeOpsColors.success, isNotNull);
      expect(CodeOpsColors.warning, isNotNull);
      expect(CodeOpsColors.error, isNotNull);
      expect(CodeOpsColors.critical, isNotNull);
      expect(CodeOpsColors.textPrimary, isNotNull);
      expect(CodeOpsColors.textSecondary, isNotNull);
      expect(CodeOpsColors.textTertiary, isNotNull);
      expect(CodeOpsColors.border, isNotNull);
      expect(CodeOpsColors.divider, isNotNull);
    });

    test('severityColors has all 4 severity values', () {
      expect(CodeOpsColors.severityColors.length, 4);
      for (final s in Severity.values) {
        expect(CodeOpsColors.severityColors.containsKey(s), isTrue,
            reason: 'Missing severity color for $s');
      }
    });

    test('jobStatusColors has all 5 status values', () {
      expect(CodeOpsColors.jobStatusColors.length, 5);
      for (final s in JobStatus.values) {
        expect(CodeOpsColors.jobStatusColors.containsKey(s), isTrue,
            reason: 'Missing job status color for $s');
      }
    });
  });
}
