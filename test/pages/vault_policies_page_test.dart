// Widget tests for VaultPoliciesPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_policies_page.dart';
import 'package:codeops/providers/vault_providers.dart';

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

  final testDenyPolicy = AccessPolicyResponse(
    id: 'p2',
    teamId: 't1',
    name: 'deny-delete-all',
    pathPattern: '/services/*',
    permissions: [PolicyPermission.delete],
    isDenyPolicy: true,
    isActive: true,
    bindingCount: 1,
    createdAt: DateTime(2026, 1, 15),
  );

  final testPage = PageResponse<AccessPolicyResponse>(
    content: [testPolicy, testDenyPolicy],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    PageResponse<AccessPolicyResponse>? page,
  }) {
    return ProviderScope(
      overrides: [
        vaultPoliciesProvider.overrideWith(
          (ref) => Future.value(page ?? testPage),
        ),
        vaultPolicyBindingsProvider.overrideWith(
          (ref, id) => Future.value(<PolicyBindingResponse>[]),
        ),
        vaultPolicyStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{'total': 2}),
        ),
        vaultPolicyDetailProvider.overrideWith(
          (ref, id) => Future.value(testPolicy),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: VaultPoliciesPage())),
    );
  }

  group('VaultPoliciesPage', () {
    testWidgets('shows Policies header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Header text "Policies" and tab text "Policies"
      expect(find.text('Policies'), findsWidgets);
    });

    testWidgets('shows two tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Policies'), findsWidgets);
      expect(find.text('Evaluate Access'), findsOneWidget);
    });

    testWidgets('shows New Policy button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Policy'), findsOneWidget);
    });

    testWidgets('shows Active Only filter chip', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Only'), findsOneWidget);
    });

    testWidgets('shows policy list items', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('read-db-secrets'), findsOneWidget);
      expect(find.text('deny-delete-all'), findsOneWidget);
    });

    testWidgets('shows path patterns', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('/services/*/db-*'), findsOneWidget);
    });

    testWidgets('shows DENY badge for deny policy', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('DENY'), findsWidgets);
    });

    testWidgets('shows permission badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('READ'), findsWidgets);
      expect(find.text('LIST'), findsOneWidget);
      expect(find.text('DELETE'), findsWidgets);
    });

    testWidgets('shows pagination info', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 policies'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no policies', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<AccessPolicyResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No policies found'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultPoliciesProvider.overrideWith(
            (ref) => Completer<PageResponse<AccessPolicyResponse>>().future,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: VaultPoliciesPage())),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Loading policies...'), findsOneWidget);
    });

    testWidgets('shows sort chips for Name and Created', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sort:'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
    });

    testWidgets('shows open detail icon on policy list items',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.open_in_new), findsNWidgets(2));
    });

    testWidgets('shows binding count in list items', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // testPolicy has bindingCount 2, testDenyPolicy has 1
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows active indicator dot', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Both test policies are active
      expect(find.byIcon(Icons.circle), findsWidgets);
    });

    testWidgets('Evaluate Access tab shows form', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Evaluate Access tab
      await tester.tap(find.text('Evaluate Access'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluate Access'), findsWidgets);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Evaluate'), findsOneWidget);
    });
  });
}
