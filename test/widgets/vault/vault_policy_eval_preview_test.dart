// Widget tests for VaultPolicyEvalPreview (CVF-004).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_policy_eval_preview.dart';

void main() {
  final testPolicy = AccessPolicyResponse(
    id: 'p1',
    teamId: 't1',
    name: 'read-db-secrets',
    pathPattern: '/services/*/db-*',
    permissions: [PolicyPermission.read],
    isDenyPolicy: false,
    isActive: true,
    bindingCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );

  final testDenyPolicy = AccessPolicyResponse(
    id: 'p2',
    teamId: 't1',
    name: 'deny-all-services',
    pathPattern: '/services/*',
    permissions: [PolicyPermission.read, PolicyPermission.write],
    isDenyPolicy: true,
    isActive: true,
    bindingCount: 0,
    createdAt: DateTime(2026, 1, 15),
  );

  final matchingSecret = SecretResponse(
    id: 's1',
    teamId: 't1',
    path: '/services/app/db-password',
    name: 'db-password',
    secretType: SecretType.static_,
    currentVersion: 1,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final nonMatchingSecret = SecretResponse(
    id: 's2',
    teamId: 't1',
    path: '/infrastructure/cache-key',
    name: 'cache-key',
    secretType: SecretType.static_,
    currentVersion: 1,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final testPoliciesPage = PageResponse<AccessPolicyResponse>(
    content: [testPolicy, testDenyPolicy],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    String policyId = 'p1',
    AccessPolicyResponse? policy,
    List<SecretResponse>? secrets,
    List<AccessPolicyResponse>? policies,
  }) {
    final secretsPage = PageResponse<SecretResponse>(
      content: secrets ?? [matchingSecret, nonMatchingSecret],
      page: 0,
      size: 20,
      totalElements: (secrets ?? [matchingSecret, nonMatchingSecret]).length,
      totalPages: 1,
      isLast: true,
    );
    final policiesPage = policies != null
        ? PageResponse<AccessPolicyResponse>(
            content: policies,
            page: 0,
            size: 20,
            totalElements: policies.length,
            totalPages: 1,
            isLast: true,
          )
        : testPoliciesPage;

    return ProviderScope(
      overrides: [
        vaultPolicyDetailProvider(policyId).overrideWith(
          (ref) => Future.value(policy ?? testPolicy),
        ),
        vaultSecretsProvider.overrideWith(
          (ref) => Future.value(secretsPage),
        ),
        vaultPoliciesProvider.overrideWith(
          (ref) => Future.value(policiesPage),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: VaultPolicyEvalPreview(policyId: policyId),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Matching Secrets section
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyEvalPreview — Matching Secrets', () {
    testWidgets('shows Matching Secrets heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Matching Secrets'), findsOneWidget);
    });

    testWidgets('shows matching secrets', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // db-password matches /services/*/db-*
      expect(find.text('db-password'), findsOneWidget);
      expect(find.text('1 matching secrets'), findsOneWidget);
    });

    testWidgets('does not show non-matching secrets', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // cache-key at /infrastructure/cache-key should not match
      expect(find.text('cache-key'), findsNothing);
    });

    testWidgets('shows ALLOWED badge for allow policy', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('ALLOWED'), findsWidgets);
    });

    testWidgets('shows DENIED badge for deny policy', (tester) async {
      await tester.pumpWidget(createWidget(
        policyId: 'p2',
        policy: testDenyPolicy,
        secrets: [
          SecretResponse(
            id: 's3',
            teamId: 't1',
            path: '/services/any',
            name: 'any-secret',
            secretType: SecretType.static_,
            currentVersion: 1,
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('DENIED'), findsWidgets);
    });

    testWidgets('shows empty state when no secrets match', (tester) async {
      await tester.pumpWidget(createWidget(
        secrets: [nonMatchingSecret],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No secrets match this pattern'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Deny-Override Evaluator section
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyEvalPreview — Evaluator', () {
    testWidgets('shows evaluator heading and form', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Deny-Override Evaluator'), findsOneWidget);
      expect(find.text('Evaluate'), findsOneWidget);
    });

    testWidgets('shows path input field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret Path'), findsOneWidget);
    });

    testWidgets('shows error for empty path', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Evaluate without entering a path
      await tester.tap(find.text('Evaluate'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid path starting with /'),
        findsOneWidget,
      );
    });

    testWidgets('evaluates path and shows ACCESS ALLOWED', (tester) async {
      // Only allow policies, no deny
      await tester.pumpWidget(createWidget(
        policies: [testPolicy],
      ));
      await tester.pumpAndSettle();

      // Enter a matching path
      await tester.enterText(
        find.widgetWithText(TextField, 'Secret Path'),
        '/services/app/db-password',
      );
      await tester.tap(find.text('Evaluate'));
      await tester.pumpAndSettle();

      expect(find.text('ACCESS ALLOWED'), findsOneWidget);
    });

    testWidgets('shows ACCESS DENIED when deny policy matches', (tester) async {
      // Create a deny policy that matches the same path as the allow policy
      final denyOnDbSecrets = AccessPolicyResponse(
        id: 'p3',
        teamId: 't1',
        name: 'deny-db-secrets',
        pathPattern: '/services/*/db-*',
        permissions: [PolicyPermission.read],
        isDenyPolicy: true,
        isActive: true,
        bindingCount: 0,
        createdAt: DateTime(2026, 1, 20),
      );
      await tester.pumpWidget(createWidget(
        policies: [testPolicy, denyOnDbSecrets],
      ));
      await tester.pumpAndSettle();

      // Enter a path that matches both allow and deny policies
      await tester.enterText(
        find.widgetWithText(TextField, 'Secret Path'),
        '/services/app/db-password',
      );
      await tester.tap(find.text('Evaluate'));
      await tester.pumpAndSettle();

      expect(find.text('ACCESS DENIED'), findsOneWidget);
    });

    testWidgets('shows default denied when no policies match', (tester) async {
      await tester.pumpWidget(createWidget(
        policies: [testPolicy],
      ));
      await tester.pumpAndSettle();

      // Enter a path that does not match
      await tester.enterText(
        find.widgetWithText(TextField, 'Secret Path'),
        '/infrastructure/cache-key',
      );
      await tester.tap(find.text('Evaluate'));
      await tester.pumpAndSettle();

      expect(find.text('ACCESS DENIED'), findsOneWidget);
      expect(find.textContaining('no matching policy'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Loading state
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultPolicyEvalPreview — loading', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultPolicyDetailProvider('p1').overrideWith(
            (ref) => Completer<AccessPolicyResponse>().future,
          ),
          vaultSecretsProvider.overrideWith(
            (ref) => Completer<PageResponse<SecretResponse>>().future,
          ),
          vaultPoliciesProvider.overrideWith(
            (ref) => Completer<PageResponse<AccessPolicyResponse>>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: VaultPolicyEvalPreview(policyId: 'p1'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
