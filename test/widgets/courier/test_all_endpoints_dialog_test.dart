// Widget tests for TestAllEndpointsDialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/test_all_endpoints_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildDialog() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const TestAllEndpointsDialog(
                  collectionId: 'col-1',
                  collectionName: 'User API',
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TestAllEndpointsDialog', () {
    testWidgets('renders dialog with header', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_all_endpoints_dialog')),
          findsOneWidget);
      expect(find.textContaining('Test All Endpoints'), findsOneWidget);
    });

    testWidgets('shows run all button', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('run_all_button')), findsOneWidget);
      expect(find.text('Run All'), findsOneWidget);
    });

    testWidgets('shows initial state message', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildDialog());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Click "Run All" to start testing.'), findsOneWidget);
    });
  });
}
