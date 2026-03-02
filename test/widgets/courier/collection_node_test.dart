// Widget tests for the _CollectionNode behavior inside CollectionSidebar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:codeops/models/courier_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/collection_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

CollectionSummaryResponse _col({
  String id = 'col-1',
  String name = 'My API',
}) =>
    CollectionSummaryResponse(id: id, name: name, folderCount: 0, requestCount: 0);

Widget buildSidebarWith(
  List<CollectionSummaryResponse> collections, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      courierCollectionsProvider.overrideWith(
        (ref) => Future.value(collections),
      ),
      courierCollectionTreeProvider.overrideWith(
        (ref, collectionId) => Future.value(<FolderTreeResponse>[]),
      ),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Row(
          children: [SizedBox(width: 280, child: CollectionSidebar())],
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('CollectionNode', () {
    testWidgets('renders collection name', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([_col(name: 'My API')]));
      await tester.pumpAndSettle();

      expect(find.text('My API'), findsOneWidget);
    });

    testWidgets('shows chevron_right icon when collapsed', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([_col()]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('tapping collection sets selectedNodeIdProvider', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([_col(id: 'col-1')]));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(selectedNodeIdProvider), isNull);

      await tester.tap(find.text('My API'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(selectedNodeIdProvider), 'col-1');
    });

    testWidgets('tapping collection adds to expandedNodesProvider', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([_col(id: 'col-1')]));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(expandedNodesProvider), isEmpty);

      await tester.tap(find.text('My API'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(expandedNodesProvider), contains('col-1'));
    });

    testWidgets('tapping expanded collection collapses it', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([_col(id: 'col-1')]));
      await tester.pumpAndSettle();

      // First tap to expand
      await tester.tap(find.text('My API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(expandedNodesProvider), contains('col-1'));

      // Second tap to collapse
      await tester.tap(find.text('My API'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(expandedNodesProvider), isNot(contains('col-1')));
    });

    testWidgets('expanded collection shows folder tree loading indicator',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courierCollectionsProvider.overrideWith(
              (ref) => Future.value([_col(id: 'col-1')]),
            ),
            courierCollectionTreeProvider.overrideWith(
              (ref, collectionId) =>
                  Completer<List<FolderTreeResponse>>().future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 280, child: CollectionSidebar()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My API'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('multiple collections are all rendered', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildSidebarWith([
        _col(id: 'col-1', name: 'Alpha API'),
        _col(id: 'col-2', name: 'Beta API'),
        _col(id: 'col-3', name: 'Gamma API'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Alpha API'), findsOneWidget);
      expect(find.text('Beta API'), findsOneWidget);
      expect(find.text('Gamma API'), findsOneWidget);
    });

    testWidgets('alphabetical sort orders collections A-Z', (tester) async {
      setSize(tester);
      await tester.pumpWidget(
        buildSidebarWith(
          [
            _col(id: 'col-1', name: 'Zebra'),
            _col(id: 'col-2', name: 'Alpha'),
          ],
          overrides: [
            sidebarSortProvider
                .overrideWith((ref) => SidebarSortOrder.alphabetical),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final alphaPos =
          tester.getTopLeft(find.text('Alpha')).dy;
      final zebraPos =
          tester.getTopLeft(find.text('Zebra')).dy;
      expect(alphaPos, lessThan(zebraPos));
    });
  });
}
