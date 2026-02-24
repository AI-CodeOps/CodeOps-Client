// Widget tests for VaultRotationHistory (CVF-005).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_rotation_history.dart';

void main() {
  final testEntries = [
    RotationHistoryResponse(
      id: 'h1',
      secretId: 's1',
      strategy: RotationStrategy.randomGenerate,
      previousVersion: 1,
      newVersion: 2,
      success: true,
      durationMs: 150,
      createdAt: DateTime(2026, 1, 10, 14, 30),
    ),
    RotationHistoryResponse(
      id: 'h2',
      secretId: 's1',
      strategy: RotationStrategy.externalApi,
      previousVersion: 2,
      newVersion: null,
      success: false,
      errorMessage: 'API timeout',
      durationMs: 5000,
      createdAt: DateTime(2026, 1, 11, 8, 0),
    ),
  ];

  Widget createWidget({
    List<RotationHistoryResponse>? entries,
  }) {
    final page = PageResponse<RotationHistoryResponse>(
      content: entries ?? testEntries,
      page: 0,
      size: 20,
      totalElements: (entries ?? testEntries).length,
      totalPages: 1,
      isLast: true,
    );

    return ProviderScope(
      overrides: [
        vaultRotationHistoryProvider('s1').overrideWith(
          (ref) => Future.value(page),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: VaultRotationHistory(secretId: 's1'),
        ),
      ),
    );
  }

  group('VaultRotationHistory', () {
    testWidgets('shows success and failure entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('shows version change', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('v1 → v2'), findsOneWidget);
    });

    testWidgets('shows error message for failed entry', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('API timeout'), findsOneWidget);
    });

    testWidgets('shows empty state when no history', (tester) async {
      await tester.pumpWidget(createWidget(entries: []));
      await tester.pumpAndSettle();

      expect(find.text('No rotation history'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultRotationHistoryProvider('s1').overrideWith(
            (ref) =>
                Completer<PageResponse<RotationHistoryResponse>>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: VaultRotationHistory(secretId: 's1'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
