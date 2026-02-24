// Widget tests for VaultPolicyDetailPage (CVF-004).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_policy_detail_page.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';

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
    createdByUserId: 'u1234567-aaaa-bbbb-cccc-ddddeeeeeeee',
    bindingCount: 2,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 15),
  );

  final testDenyPolicy = AccessPolicyResponse(
    id: 'p2',
    teamId: 't1',
    name: 'deny-delete-all',
    description: 'Deny deleting any secret',
    pathPattern: '/services/*',
    permissions: [PolicyPermission.delete],
    isDenyPolicy: true,
    isActive: true,
    bindingCount: 1,
    createdAt: DateTime(2026, 1, 15),
  );

  final testBindings = [
    PolicyBindingResponse(
      id: 'b1',
      policyId: 'p1',
      policyName: 'read-db-secrets',
      bindingType: BindingType.user,
      bindingTargetId: 'u1234567-0000-0000-0000-000000000001',
      createdAt: DateTime(2026, 1, 5),
    ),
    PolicyBindingResponse(
      id: 'b2',
      policyId: 'p1',
      policyName: 'read-db-secrets',
      bindingType: BindingType.team,
      bindingTargetId: 't7654321-0000-0000-0000-000000000001',
      createdAt: DateTime(2026, 1, 10),
    ),
  ];

  final testPoliciesPage = PageResponse<AccessPolicyResponse>(
    content: [testPolicy, testDenyPolicy],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  final testSecretsPage = PageResponse<SecretResponse>(
    content: [
      SecretResponse(
        id: 's1',
        teamId: 't1',
        path: '/services/app/db-password',
        name: 'db-password',
        secretType: SecretType.static_,
        currentVersion: 1,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 1,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    String policyId = 'p1',
    AccessPolicyResponse? policy,
    List<PolicyBindingResponse>? bindings,
  }) {
    return ProviderScope(
      overrides: [
        vaultPolicyDetailProvider(policyId).overrideWith(
          (ref) => Future.value(policy ?? testPolicy),
        ),
        vaultPolicyBindingsProvider(policyId).overrideWith(
          (ref) => Future.value(bindings ?? testBindings),
        ),
        vaultPoliciesProvider.overrideWith(
          (ref) => Future.value(testPoliciesPage),
        ),
        vaultPolicyStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{'total': 2}),
        ),
        vaultSecretsProvider.overrideWith(
          (ref) => Future.value(testSecretsPage),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: VaultPolicyDetailPage(policyId: policyId),
        ),
      ),
    );
  }

  // Desktop-sized surface to avoid RenderFlex overflow in tests.
  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDetailPage header', () {
    testWidgets('shows policy name in header', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('read-db-secrets'), findsWidgets);
    });

    testWidgets('shows path pattern in header', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('/services/*/db-*'), findsWidgets);
    });

    testWidgets('shows Active badge for active policy', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsWidgets);
    });

    testWidgets('shows Inactive badge for inactive policy', (tester) async {
      setDesktopSize(tester);
      final inactive = AccessPolicyResponse(
        id: 'p1',
        teamId: 't1',
        name: 'inactive-policy',
        pathPattern: '/test/*',
        permissions: [PolicyPermission.read],
        isDenyPolicy: false,
        isActive: false,
        bindingCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(createWidget(policy: inactive));
      await tester.pumpAndSettle();

      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('shows DENY badge for deny policy', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(
        createWidget(policyId: 'p2', policy: testDenyPolicy),
      );
      await tester.pumpAndSettle();

      expect(find.text('DENY'), findsOneWidget);
    });

    testWidgets('shows binding count chip', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('shows back button', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows actions menu', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tab tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDetailPage tabs', () {
    testWidgets('shows three tabs', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Overview'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bindings'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Impact Preview'), findsOneWidget);
    });

    testWidgets('Overview tab shows policy details', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Path Pattern'), findsWidgets);
      expect(find.text('Permissions'), findsOneWidget);
    });

    testWidgets('Overview tab shows permission badges', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('READ'), findsWidgets);
      expect(find.text('LIST'), findsWidgets);
    });

    testWidgets('Overview tab shows path pattern help', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Path Pattern Matching'), findsOneWidget);
    });

    testWidgets('Bindings tab shows binding list', (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap the Tab widget specifically
      await tester.tap(find.widgetWithText(Tab, 'Bindings'));
      await tester.pumpAndSettle();

      expect(find.text('Policy Bindings'), findsOneWidget);
      expect(find.text('Add Binding'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);
      expect(find.text('TEAM'), findsOneWidget);
    });

    testWidgets('Bindings tab shows empty state when no bindings',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget(bindings: []));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Bindings'));
      await tester.pumpAndSettle();

      expect(find.text('No bindings'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Actions menu tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDetailPage actions', () {
    testWidgets('actions menu shows Edit, Deactivate, Copy, Delete',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit Policy'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      expect(find.text('Copy Path Pattern'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('actions menu shows Activate for inactive policy',
        (tester) async {
      setDesktopSize(tester);
      final inactive = AccessPolicyResponse(
        id: 'p1',
        teamId: 't1',
        name: 'inactive-policy',
        pathPattern: '/test/*',
        permissions: [PolicyPermission.read],
        isDenyPolicy: false,
        isActive: false,
        bindingCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(createWidget(policy: inactive));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Activate'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Loading / Error states
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyDetailPage states', () {
    testWidgets('shows loading indicator', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultPolicyDetailProvider('p1').overrideWith(
            (ref) => Completer<AccessPolicyResponse>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: VaultPolicyDetailPage(policyId: 'p1'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error panel on load failure', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultPolicyDetailProvider('p1').overrideWith(
            (ref) => Future<AccessPolicyResponse>.error(
              Exception('Network error'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: VaultPolicyDetailPage(policyId: 'p1'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
