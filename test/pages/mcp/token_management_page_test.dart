// Widget tests for TokenManagementPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/pages/mcp/token_management_page.dart';
import 'package:codeops/providers/mcp_profile_providers.dart';

void main() {
  const profileId = 'dev-1';

  final tokens = [
    McpApiToken(
      id: 'tok-1',
      name: 'Claude Code Laptop',
      tokenPrefix: 'mcp_a1b2...',
      status: TokenStatus.active,
      createdAt: DateTime(2026, 2, 1),
      lastUsedAt: DateTime(2026, 3, 1),
      expiresAt: DateTime(2026, 6, 1),
      scopesJson: '["read","write"]',
    ),
    McpApiToken(
      id: 'tok-2',
      name: 'CI Pipeline',
      tokenPrefix: 'mcp_x9y8...',
      status: TokenStatus.revoked,
      createdAt: DateTime(2026, 1, 15),
      scopesJson: '["read"]',
    ),
    McpApiToken(
      id: 'tok-3',
      name: 'Old Token',
      tokenPrefix: 'mcp_q3r4...',
      status: TokenStatus.expired,
      createdAt: DateTime(2025, 6, 1),
      expiresAt: DateTime(2025, 12, 31),
      scopesJson: '["read","write","admin"]',
    ),
  ];

  Widget createWidget({
    bool loading = false,
    bool empty = false,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        profileTokensProvider.overrideWith((ref, id) {
          if (loading) return Completer<List<McpApiToken>>().future;
          if (error) return Future<List<McpApiToken>>.error('Server error');
          if (empty) return Future.value([]);
          return Future.value(tokens);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: TokenManagementPage(profileId: profileId),
        ),
      ),
    );
  }

  group('TokenManagementPage', () {
    testWidgets('renders header with breadcrumb', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profiles'), findsOneWidget);
      expect(find.text('Token Management'), findsOneWidget);
    });

    testWidgets('renders token list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Claude Code Laptop'), findsOneWidget);
      expect(find.text('CI Pipeline'), findsOneWidget);
      expect(find.text('Old Token'), findsOneWidget);
    });

    testWidgets('renders status badges with correct labels',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Revoked'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('renders token prefixes', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('mcp_a1b2...'), findsOneWidget);
      expect(find.text('mcp_x9y8...'), findsOneWidget);
      expect(find.text('mcp_q3r4...'), findsOneWidget);
    });

    testWidgets('renders create token button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Token'), findsOneWidget);
    });

    testWidgets('renders revoke button only for active tokens',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Only 1 active token should have Revoke button
      expect(find.text('Revoke'), findsOneWidget);
    });

    testWidgets('opens create token dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Token'));
      await tester.pumpAndSettle();

      expect(find.text('Token Name'), findsOneWidget);
      expect(find.text('Expires:'), findsOneWidget);
      expect(find.text('Scopes:'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders empty state when no tokens', (tester) async {
      await tester.pumpWidget(createWidget(empty: true));
      await tester.pumpAndSettle();

      expect(find.text('No tokens yet'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
