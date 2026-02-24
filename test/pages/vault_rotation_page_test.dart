// Widget tests for VaultRotationPage (CVF-005).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_rotation_page.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';

void main() {
  final testSecrets = [
    SecretResponse(
      id: 's1',
      teamId: 't1',
      path: '/services/app/db-password',
      name: 'db-password',
      secretType: SecretType.static_,
      currentVersion: 3,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    SecretResponse(
      id: 's2',
      teamId: 't1',
      path: '/services/app/api-key',
      name: 'api-key',
      secretType: SecretType.static_,
      currentVersion: 1,
      isActive: true,
      createdAt: DateTime(2026, 1, 5),
    ),
  ];

  final testSecretsPage = PageResponse<SecretResponse>(
    content: testSecrets,
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  final testPolicy = RotationPolicyResponse(
    id: 'rp1',
    secretId: 's1',
    secretPath: '/services/app/db-password',
    strategy: RotationStrategy.randomGenerate,
    rotationIntervalHours: 24,
    randomLength: 32,
    isActive: true,
    failureCount: 0,
    maxFailures: 3,
    lastRotatedAt: DateTime(2026, 1, 15, 10, 0),
    nextRotationAt: DateTime.now().add(const Duration(hours: 12)),
    createdAt: DateTime(2026, 1, 1),
  );

  final testHistory = PageResponse<RotationHistoryResponse>(
    content: [
      RotationHistoryResponse(
        id: 'h1',
        secretId: 's1',
        strategy: RotationStrategy.randomGenerate,
        previousVersion: 2,
        newVersion: 3,
        success: true,
        durationMs: 120,
        createdAt: DateTime(2026, 1, 15, 10, 0),
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 1,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        vaultSecretsProvider.overrideWith(
          (ref) => Future.value(testSecretsPage),
        ),
        vaultRotationPolicyProvider('s1').overrideWith(
          (ref) => Future.value(testPolicy),
        ),
        vaultRotationPolicyProvider('s2').overrideWith(
          (ref) => Future<RotationPolicyResponse>.error(
            Exception('Not found'),
          ),
        ),
        vaultRotationHistoryProvider('s1').overrideWith(
          (ref) => Future.value(testHistory),
        ),
        vaultRotationStatsProvider('s1').overrideWith(
          (ref) => Future.value(<String, int>{
            'total': 10,
            'successful': 9,
            'failed': 1,
            'averageDurationMs': 150,
          }),
        ),
        vaultSecretDetailProvider('s1').overrideWith(
          (ref) => Future.value(testSecrets[0]),
        ),
        vaultSecretDetailProvider('s2').overrideWith(
          (ref) => Future.value(testSecrets[1]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: VaultRotationPage()),
      ),
    );
  }

  // Desktop-sized surface to avoid overflow in tests.
  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  group('VaultRotationPage — header', () {
    testWidgets('shows Rotation title', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rotation'), findsOneWidget);
    });

    testWidgets('shows Schedule and Activity tabs', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Schedule'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Activity'), findsOneWidget);
    });

    testWidgets('shows Add Rotation Policy button', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add Rotation Policy'), findsOneWidget);
    });
  });

  group('VaultRotationPage — schedule tab', () {
    testWidgets('shows secret paths in schedule table', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('/services/app/db-password'), findsOneWidget);
      expect(find.text('/services/app/api-key'), findsOneWidget);
    });

    testWidgets('shows table headers', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret Path'), findsOneWidget);
      expect(find.text('Strategy'), findsOneWidget);
      expect(find.text('Interval'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('shows No policy for secrets without rotation',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No policy'), findsOneWidget);
    });

    testWidgets('shows status badge for secret with rotation policy',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets('shows strategy name for secret with rotation policy',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Random Generate'), findsOneWidget);
    });
  });

  group('VaultRotationPage — activity tab', () {
    testWidgets('shows prompt to select secret when none selected',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Activity tab.
      await tester.tap(find.widgetWithText(Tab, 'Activity'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select a secret from the Schedule tab to view activity.'),
        findsOneWidget,
      );
    });
  });

  group('VaultRotationPage — loading', () {
    testWidgets('shows loading indicator while secrets load', (tester) async {
      setDesktopSize(tester);
      final widget = ProviderScope(
        overrides: [
          vaultSecretsProvider.overrideWith(
            (ref) => Completer<PageResponse<SecretResponse>>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: VaultRotationPage()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
