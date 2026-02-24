// Widget tests for VaultRotationStatusBadge (CVF-005).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_rotation_status_badge.dart';

void main() {
  RotationPolicyResponse makePolicy({
    bool isActive = true,
    int failureCount = 0,
    DateTime? nextRotationAt,
    int? maxFailures,
  }) {
    return RotationPolicyResponse(
      id: 'rp1',
      secretId: 's1',
      strategy: RotationStrategy.randomGenerate,
      rotationIntervalHours: 24,
      isActive: isActive,
      failureCount: failureCount,
      maxFailures: maxFailures,
      nextRotationAt: nextRotationAt,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Widget createWidget(RotationPolicyResponse policy) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(child: VaultRotationStatusBadge(policy: policy)),
      ),
    );
  }

  group('VaultRotationStatusBadge', () {
    testWidgets('shows Healthy for active policy with future next rotation',
        (tester) async {
      final policy = makePolicy(
        nextRotationAt: DateTime.now().add(const Duration(hours: 2)),
      );
      await tester.pumpWidget(createWidget(policy));

      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets('shows Due Soon when next rotation within 1 hour',
        (tester) async {
      final policy = makePolicy(
        nextRotationAt: DateTime.now().add(const Duration(minutes: 30)),
      );
      await tester.pumpWidget(createWidget(policy));

      expect(find.text('Due Soon'), findsOneWidget);
    });

    testWidgets('shows Overdue when next rotation is past', (tester) async {
      final policy = makePolicy(
        nextRotationAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await tester.pumpWidget(createWidget(policy));

      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('shows Failed when failure count > 0', (tester) async {
      final policy = makePolicy(
        failureCount: 2,
        nextRotationAt: DateTime.now().add(const Duration(hours: 2)),
      );
      await tester.pumpWidget(createWidget(policy));

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('shows Disabled for inactive policy', (tester) async {
      final policy = makePolicy(isActive: false);
      await tester.pumpWidget(createWidget(policy));

      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('computeRotationStatus', () {
    test('disabled takes priority over failure', () {
      final policy = makePolicy(isActive: false, failureCount: 3);
      expect(computeRotationStatus(policy), RotationStatus.disabled);
    });

    test('failed takes priority over overdue', () {
      final policy = makePolicy(
        failureCount: 1,
        nextRotationAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(computeRotationStatus(policy), RotationStatus.failed);
    });

    test('healthy when nextRotationAt is null', () {
      final policy = makePolicy(nextRotationAt: null);
      expect(computeRotationStatus(policy), RotationStatus.healthy);
    });
  });
}
