// Widget tests for VaultTransitStats (CVF-006).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_transit_stats.dart';

void main() {
  Widget createWidget({Map<String, int>? stats}) {
    return ProviderScope(
      overrides: [
        vaultTransitStatsProvider.overrideWith(
          (ref) => Future.value(stats ?? <String, int>{
            'total': 5,
            'active': 3,
            'totalVersions': 12,
          }),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: VaultTransitStats()),
      ),
    );
  }

  group('VaultTransitStats', () {
    testWidgets('shows total keys count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('Keys'), findsOneWidget);
    });

    testWidgets('shows active keys count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows total versions count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Versions'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultTransitStatsProvider.overrideWith(
            (ref) => Completer<Map<String, int>>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: VaultTransitStats()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
