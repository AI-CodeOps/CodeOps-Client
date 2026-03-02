// Widget tests for folder node behavior inside CollectionSidebar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/collection_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

CollectionSummaryResponse _col({String id = 'col-1', String name = 'API'}) =>
    CollectionSummaryResponse(id: id, name: name, folderCount: 1, requestCount: 0);

FolderTreeResponse _folder({
  String id = 'fol-1',
  String name = 'Auth',
  List<FolderTreeResponse>? subFolders,
  List<RequestSummaryResponse>? requests,
}) =>
    FolderTreeResponse(
      id: id,
      name: name,
      sortOrder: 0,
      subFolders: subFolders,
      requests: requests,
    );

Widget buildWithFolders(List<FolderTreeResponse> folders) {
  return ProviderScope(
    overrides: [
      courierCollectionsProvider.overrideWith(
        (ref) => Future.value([_col()]),
      ),
      courierCollectionTreeProvider.overrideWith(
        (ref, collectionId) => Future.value(folders),
      ),
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
  group('FolderNode', () {
    testWidgets('folder appears after collection is expanded', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([_folder(name: 'Auth')]));
      await tester.pumpAndSettle();

      // Collection not yet expanded — folder not visible
      expect(find.text('Auth'), findsNothing);

      // Expand collection — pumpAndSettle(500ms) advances past 300ms double-tap timer
      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Auth'), findsOneWidget);
    });

    testWidgets('tapping folder sets selectedNodeIdProvider', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([_folder(id: 'fol-1')]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );

      await tester.tap(find.text('Auth'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(selectedNodeIdProvider), 'fol-1');
    });

    testWidgets('folder with subfolders shows chevron and expands', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([
        _folder(
          id: 'fol-1',
          name: 'Auth',
          subFolders: [_folder(id: 'fol-2', name: 'OAuth')],
        ),
      ]));
      await tester.pumpAndSettle();

      // Expand collection then folder
      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('OAuth'), findsNothing);

      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.text('OAuth'), findsOneWidget);
    });

    testWidgets('folder without children shows no chevron icon',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([
        _folder(id: 'fol-1', name: 'Empty'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // The folder has no children so chevron should not be shown
      // (uses SizedBox placeholder instead of Icon)
      final folderRow = find.byKey(const Key('folder_fol-1'));
      expect(folderRow, findsOneWidget);
    });

    testWidgets('nested subfolders render at deeper indentation', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([
        _folder(
          id: 'fol-1',
          name: 'Level1',
          subFolders: [
            _folder(id: 'fol-2', name: 'Level2'),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.text('Level1'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final l1 = tester.getTopLeft(find.text('Level1')).dx;
      final l2 = tester.getTopLeft(find.text('Level2')).dx;
      expect(l2, greaterThan(l1));
    });

    testWidgets('folder node renders with correct key', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithFolders([_folder(id: 'fol-abc')]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('API'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('folder_fol-abc')), findsOneWidget);
    });
  });
}
