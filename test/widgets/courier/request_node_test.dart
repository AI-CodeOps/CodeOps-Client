// Widget tests for request node behavior inside CollectionSidebar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/models/courier_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/collection_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

CollectionSummaryResponse _col() =>
    const CollectionSummaryResponse(id: 'col-1', name: 'API');

FolderTreeResponse _folderWithRequest({
  RequestSummaryResponse? request,
}) =>
    FolderTreeResponse(
      id: 'fol-1',
      name: 'Auth',
      sortOrder: 0,
      subFolders: [],
      requests: [
        request ??
            const RequestSummaryResponse(
              id: 'req-1',
              name: 'Login',
              method: CourierHttpMethod.post,
              url: 'http://localhost/login',
              sortOrder: 0,
            ),
      ],
    );

Widget buildWithRequest({RequestSummaryResponse? request}) {
  return ProviderScope(
    overrides: [
      courierCollectionsProvider.overrideWith(
        (ref) => Future.value([_col()]),
      ),
      courierCollectionTreeProvider.overrideWith(
        (ref, collectionId) =>
            Future.value([_folderWithRequest(request: request)]),
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

/// Expands collection → folder to make request visible.
/// Uses pumpAndSettle(500ms) to advance past the 300ms double-tap timer
/// that GestureDetector uses when both onTap and onDoubleTap are registered.
Future<void> expandAll(WidgetTester tester) async {
  await tester.tap(find.text('API'));
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  await tester.tap(find.text('Auth'));
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
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
  group('RequestNode', () {
    testWidgets('renders request name inside expanded folder', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows method badge for the request', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      expect(find.byType(MethodBadge), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
    });

    testWidgets('shows GET badge for GET request', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest(
        request: const RequestSummaryResponse(
          id: 'req-2',
          name: 'List Users',
          method: CourierHttpMethod.get,
          url: 'http://localhost/users',
        ),
      ));
      await tester.pumpAndSettle();

      await expandAll(tester);

      expect(find.text('GET'), findsOneWidget);
    });

    testWidgets('tapping request sets selectedNodeIdProvider', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );

      await tester.tap(find.text('Login'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(selectedNodeIdProvider), 'req-1');
    });

    testWidgets('tapping request opens a new tab in openRequestTabsProvider',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(openRequestTabsProvider), isEmpty);

      await tester.tap(find.text('Login'));
      await tester.pump(const Duration(milliseconds: 500));

      final tabs = container.read(openRequestTabsProvider);
      expect(tabs, hasLength(1));
      expect(tabs.first.requestId, 'req-1');
      expect(tabs.first.method, CourierHttpMethod.post);
    });

    testWidgets('tapping same request twice does not duplicate tabs',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );

      await tester.tap(find.text('Login'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Login'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(openRequestTabsProvider), hasLength(1));
    });

    testWidgets('request node has widget key request_<id>', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildWithRequest());
      await tester.pumpAndSettle();

      await expandAll(tester);

      expect(find.byKey(const Key('request_req-1')), findsOneWidget);
    });
  });
}
