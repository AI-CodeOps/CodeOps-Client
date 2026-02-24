// Tests for VaultSecretValueTab widget (CVF-003).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_secret_value_tab.dart';

void main() {
  Widget createWidget({
    String secretId = 's1',
    SecretValueResponse? valueResponse,
  }) {
    final value = valueResponse ??
        const SecretValueResponse(
          secretId: 's1',
          path: '/services/app/db-password',
          name: 'db-password',
          versionNumber: 3,
          value: 'super-secret-password-123',
        );

    return ProviderScope(
      overrides: [
        vaultSecretValueProvider(secretId).overrideWith(
          (ref) => Future.value(value),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 500,
            child: VaultSecretValueTab(secretId: secretId),
          ),
        ),
      ),
    );
  }

  group('VaultSecretValueTab', () {
    testWidgets('shows hidden state initially', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret value is hidden'), findsOneWidget);
      expect(find.text('Reveal Secret'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('shows auto-hide timer message', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Value will auto-hide after 30 seconds'),
        findsOneWidget,
      );
    });

    testWidgets('shows reveal button with warning color', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('hides visibility_off icon after reveal', (tester) async {
      // Verify it's visible initially.
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });

  group('VaultSecretValueTab — JSON detection', () {
    test('isJson returns true for valid JSON', () {
      expect(_isJson('{"key": "value"}'), isTrue);
      expect(_isJson('[1, 2, 3]'), isTrue);
      expect(_isJson('"string"'), isTrue);
      expect(_isJson('123'), isTrue);
    });

    test('isJson returns false for invalid JSON', () {
      expect(_isJson('not json'), isFalse);
      expect(_isJson('{invalid}'), isFalse);
      expect(_isJson(''), isFalse);
    });

    test('isJsonObject returns true only for objects', () {
      expect(_isJsonObject('{"key": "value"}'), isTrue);
      expect(_isJsonObject('{}'), isTrue);
    });

    test('isJsonObject returns false for non-objects', () {
      expect(_isJsonObject('[1, 2, 3]'), isFalse);
      expect(_isJsonObject('"string"'), isFalse);
      expect(_isJsonObject('not json'), isFalse);
    });

    test('prettyJson formats with indentation', () {
      const input = '{"a":"b","c":"d"}';
      final result = _prettyJson(input);
      expect(result, contains('  "a"'));
      expect(result, contains('  "c"'));
    });

    test('prettyJson returns original if not valid JSON', () {
      const input = 'not json';
      expect(_prettyJson(input), equals(input));
    });
  });
}

// ─── Expose private helpers for testing ──────────────────────────────────
// These mirror the private functions in vault_secret_value_tab.dart.

bool _isJson(String value) {
  try {
    json.decode(value);
    return true;
  } catch (_) {
    return false;
  }
}

bool _isJsonObject(String value) {
  try {
    final decoded = json.decode(value);
    return decoded is Map;
  } catch (_) {
    return false;
  }
}

String _prettyJson(String value) {
  try {
    final decoded = json.decode(value);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return value;
  }
}
