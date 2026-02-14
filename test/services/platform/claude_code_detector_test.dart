import 'package:codeops/services/platform/claude_code_detector.dart';
import 'package:codeops/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClaudeCodeDetector', () {
    late ClaudeCodeDetector detector;

    setUp(() {
      detector = const ClaudeCodeDetector();
    });

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    test('can be instantiated with const constructor', () {
      const d = ClaudeCodeDetector();
      expect(d, isA<ClaudeCodeDetector>());
    });

    test('two const instances are identical', () {
      const a = ClaudeCodeDetector();
      const b = ClaudeCodeDetector();
      expect(identical(a, b), isTrue);
    });

    // -----------------------------------------------------------------------
    // isInstalled — API contract (must return bool, never throw)
    // -----------------------------------------------------------------------

    test('isInstalled returns a bool and does not throw', () async {
      final result = await detector.isInstalled();
      expect(result, isA<bool>());
    });

    // -----------------------------------------------------------------------
    // getVersion — API contract (must return String? and never throw)
    // -----------------------------------------------------------------------

    test('getVersion returns String? and does not throw', () async {
      final result = await detector.getVersion();
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('getVersion returns semver format when a version is found', () async {
      final result = await detector.getVersion();
      if (result != null) {
        expect(
          RegExp(r'^\d+\.\d+\.\d+$').hasMatch(result),
          isTrue,
          reason: 'Version "$result" should be in major.minor.patch format',
        );
      }
    });

    // -----------------------------------------------------------------------
    // getExecutablePath — API contract (must return String? and never throw)
    // -----------------------------------------------------------------------

    test('getExecutablePath returns String? and does not throw', () async {
      final result = await detector.getExecutablePath();
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('getExecutablePath returns a non-empty path when found', () async {
      final result = await detector.getExecutablePath();
      if (result != null) {
        expect(result.isNotEmpty, isTrue);
        expect(result.contains('claude'), isTrue);
      }
    });

    // -----------------------------------------------------------------------
    // validate — API contract (must return a ClaudeCodeStatus, never throw)
    // -----------------------------------------------------------------------

    test('validate returns a ClaudeCodeStatus and does not throw', () async {
      final result = await detector.validate();
      expect(result, isA<ClaudeCodeStatus>());
    });

    test('validate returns a recognized status value', () async {
      final result = await detector.validate();
      expect(
        ClaudeCodeStatus.values.contains(result),
        isTrue,
        reason: 'validate() should return a member of ClaudeCodeStatus',
      );
    });

    test('validate result is consistent with isInstalled', () async {
      final installed = await detector.isInstalled();
      final status = await detector.validate();

      if (!installed) {
        expect(status, ClaudeCodeStatus.notInstalled);
      } else {
        // If installed, status should be one of the post-install states.
        expect(
          status,
          isIn([
            ClaudeCodeStatus.available,
            ClaudeCodeStatus.versionTooOld,
            ClaudeCodeStatus.error,
          ]),
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // ClaudeCodeStatus enum
  // -------------------------------------------------------------------------

  group('ClaudeCodeStatus', () {
    test('has exactly 4 values', () {
      expect(ClaudeCodeStatus.values.length, 4);
    });

    test('contains all expected variants', () {
      expect(ClaudeCodeStatus.values, containsAll([
        ClaudeCodeStatus.available,
        ClaudeCodeStatus.notInstalled,
        ClaudeCodeStatus.versionTooOld,
        ClaudeCodeStatus.error,
      ]));
    });

    test('displayName for available is "Available"', () {
      expect(ClaudeCodeStatus.available.displayName, 'Available');
    });

    test('displayName for notInstalled is "Not Installed"', () {
      expect(ClaudeCodeStatus.notInstalled.displayName, 'Not Installed');
    });

    test('displayName for versionTooOld is "Version Too Old"', () {
      expect(ClaudeCodeStatus.versionTooOld.displayName, 'Version Too Old');
    });

    test('displayName for error is "Error"', () {
      expect(ClaudeCodeStatus.error.displayName, 'Error');
    });

    test('every variant has a non-empty displayName', () {
      for (final status in ClaudeCodeStatus.values) {
        expect(
          status.displayName.isNotEmpty,
          isTrue,
          reason: '$status should have a non-empty displayName',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // AppConstants.minClaudeCodeVersion sanity check
  // -------------------------------------------------------------------------

  group('AppConstants.minClaudeCodeVersion', () {
    test('is a valid semver string', () {
      final version = AppConstants.minClaudeCodeVersion;
      expect(
        RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version),
        isTrue,
        reason:
            'minClaudeCodeVersion "$version" should be in major.minor.patch '
            'format',
      );
    });

    test('is not empty', () {
      expect(AppConstants.minClaudeCodeVersion.isNotEmpty, isTrue);
    });
  });
}
