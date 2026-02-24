// Widget tests for VaultPolicyDialog (CVF-004).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_policy_dialog.dart';

void main() {
  final testPolicy = AccessPolicyResponse(
    id: 'p1',
    teamId: 't1',
    name: 'read-db-secrets',
    description: 'Allow reading DB secrets',
    pathPattern: '/services/*/db-*',
    permissions: [PolicyPermission.read, PolicyPermission.list],
    isDenyPolicy: false,
    isActive: true,
    bindingCount: 2,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidget({AccessPolicyResponse? policy}) {
    return ProviderScope(
      overrides: [
        vaultPoliciesProvider.overrideWith(
          (ref) => Future.value(PageResponse<AccessPolicyResponse>.empty()),
        ),
        vaultPolicyStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{'total': 0}),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VaultPolicyDialog(policy: policy),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Create mode tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDialog — create mode', () {
    testWidgets('shows Create Policy title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Policy'), findsOneWidget);
    });

    testWidgets('shows Name, Path Pattern, Description fields',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Path Pattern *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('shows all five permission chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Rotate'), findsOneWidget);
    });

    testWidgets('shows Deny Policy toggle', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Deny Policy'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows Create and Cancel buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('validates empty name on submit', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Try to submit without filling any fields
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('validates path must start with /', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill name but bad path
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'test-policy',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Path Pattern *'),
        'bad-path',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Path must start with /'), findsOneWidget);
    });

    testWidgets('shows deny warning when deny toggle is on', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Toggle deny on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('DENY the selected permissions'),
        findsOneWidget,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Edit mode tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDialog — edit mode', () {
    testWidgets('shows Edit Policy title', (tester) async {
      await tester.pumpWidget(createWidget(policy: testPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Policy'), findsOneWidget);
    });

    testWidgets('pre-populates name field', (tester) async {
      await tester.pumpWidget(createWidget(policy: testPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Name *'),
      );
      expect(nameField.controller?.text, 'read-db-secrets');
    });

    testWidgets('pre-populates path pattern field', (tester) async {
      await tester.pumpWidget(createWidget(policy: testPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final pathField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Path Pattern *'),
      );
      expect(pathField.controller?.text, '/services/*/db-*');
    });

    testWidgets('shows Save button in edit mode', (tester) async {
      await tester.pumpWidget(createWidget(policy: testPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog', (tester) async {
      await tester.pumpWidget(createWidget(policy: testPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Policy'), findsNothing);
    });
  });
}
