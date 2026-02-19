// Widget tests for CreateSecretDialog.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/widgets/vault/create_secret_dialog.dart';

void main() {
  Widget createWidget() {
    return ProviderScope(
      overrides: [
        // Override to prevent real API calls
        vaultSecretsProvider.overrideWith(
          (ref) => Completer<PageResponse<SecretResponse>>().future,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CreateSecretDialog(),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  group('CreateSecretDialog', () {
    testWidgets('shows dialog title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Secret'), findsOneWidget);
    });

    testWidgets('shows required form fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Path *'), findsOneWidget);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Value *'), findsOneWidget);
    });

    testWidgets('shows Cancel and Create buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('validates path starts with /', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter invalid path
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Path *'),
        'no-slash',
      );
      // Enter name and value to pass other validations
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'test-secret',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Value *'),
        'my-value',
      );

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Path must start with /'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Create without filling anything
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Path is required'), findsOneWidget);
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Value is required'), findsOneWidget);
    });

    testWidgets('cancel closes dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Secret'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Secret'), findsNothing);
    });
  });
}
