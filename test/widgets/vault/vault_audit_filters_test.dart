// Widget tests for VaultAuditFilters (CVF-008).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_audit_filters.dart';

void main() {
  Widget createWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: VaultAuditFilters()),
        ),
      ),
    );
  }

  group('VaultAuditFilters', () {
    testWidgets('shows Apply and Clear buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('shows quick range chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('1h'), findsOneWidget);
      expect(find.text('6h'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('shows time range pickers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNWidgets(2));
    });

    testWidgets('shows text filter fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'User ID'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Path'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Resource ID'), findsOneWidget);
    });

    testWidgets('shows filter icon on Apply button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });
}
