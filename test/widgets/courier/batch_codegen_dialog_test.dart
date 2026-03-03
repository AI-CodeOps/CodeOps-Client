// Widget tests for BatchCodegenDialog.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/widgets/courier/batch_codegen_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

final _collections = [
  const CollectionSummaryResponse(id: 'col-1', name: 'User API'),
  const CollectionSummaryResponse(id: 'col-2', name: 'Auth API'),
];

Widget buildBatchDialog({
  List<CollectionSummaryResponse> collections = const [],
}) {
  return ProviderScope(
    overrides: [
      courierCollectionsProvider.overrideWith((ref) => collections),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const BatchCodegenDialog(),
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
  group('BatchCodegenDialog', () {
    testWidgets('renders dialog with header', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBatchDialog(collections: _collections));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_codegen_dialog')), findsOneWidget);
      expect(find.text('Batch Code Generation'), findsOneWidget);
    });

    testWidgets('shows collection selector', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBatchDialog(collections: _collections));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_collection_selector')), findsOneWidget);
    });

    testWidgets('shows language selector', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBatchDialog(collections: _collections));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('batch_language_selector')), findsOneWidget);
    });

    testWidgets('shows generate button disabled when no collection selected',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBatchDialog(collections: _collections));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
          find.byKey(const Key('batch_generate_button')));
      expect(button.onPressed, isNull);
    });
  });
}
