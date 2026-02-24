// Widget tests for VaultRotationPolicyDialog (CVF-005).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_rotation_policy_dialog.dart';

void main() {
  final existingPolicy = RotationPolicyResponse(
    id: 'rp1',
    secretId: 's1',
    strategy: RotationStrategy.randomGenerate,
    rotationIntervalHours: 48,
    randomLength: 64,
    randomCharset: 'abc123',
    isActive: true,
    failureCount: 0,
    maxFailures: 5,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidget({RotationPolicyResponse? policy}) {
    return ProviderScope(
      overrides: [
        vaultPoliciesProvider.overrideWith(
          (ref) => Future.value(PageResponse<AccessPolicyResponse>.empty()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: VaultRotationPolicyDialog(
                    secretId: 's1',
                    secretPath: '/services/app/db-password',
                    existingPolicy: policy,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('VaultRotationPolicyDialog — create mode', () {
    testWidgets('shows Create Rotation Policy title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Rotation Policy'), findsOneWidget);
    });

    testWidgets('shows strategy dropdown and interval field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Strategy *'), findsOneWidget);
      expect(find.text('Interval (hours) *'), findsOneWidget);
    });

    testWidgets('shows Create and Cancel buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows secret path', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Secret: /services/app/db-password'),
        findsOneWidget,
      );
    });
  });

  group('VaultRotationPolicyDialog — edit mode', () {
    testWidgets('shows Edit Rotation Policy title', (tester) async {
      await tester.pumpWidget(createWidget(policy: existingPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Rotation Policy'), findsOneWidget);
    });

    testWidgets('shows Save button in edit mode', (tester) async {
      await tester.pumpWidget(createWidget(policy: existingPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog', (tester) async {
      await tester.pumpWidget(createWidget(policy: existingPolicy));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Rotation Policy'), findsNothing);
    });
  });
}
