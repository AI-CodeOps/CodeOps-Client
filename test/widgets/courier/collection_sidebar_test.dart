// Widget tests for CollectionSidebar.
import 'dart:async';

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

/// Wraps [CollectionSidebar] in a [ProviderScope] + [MaterialApp].
Widget buildSidebar({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      courierCollectionsProvider.overrideWith(
        (ref) => Future.value(<CollectionSummaryResponse>[]),
      ),
      ...overrides,
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
  );
}

/// A single stub collection for use in tests.
CollectionSummaryResponse _stubCollection({
  String id = 'col-1',
  String name = 'My API',
}) =>
    CollectionSummaryResponse(
      id: id,
      name: name,
      folderCount: 0,
      requestCount: 0,
    );

void setStandardSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('CollectionSidebar', () {
    testWidgets('renders without error', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.byType(CollectionSidebar), findsOneWidget);
    });

    testWidgets('shows COLLECTIONS header label', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('COLLECTIONS'), findsOneWidget);
    });

    testWidgets('shows sort menu button', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sort_menu')), findsOneWidget);
    });

    testWidgets('shows new collection button', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('new_collection_button')), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sidebar_search')), findsOneWidget);
    });

    testWidgets('shows loading indicator while collections load',
        (tester) async {
      setStandardSize(tester);
      // Use a Future that never resolves during pump
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courierCollectionsProvider.overrideWith(
              (ref) => Completer<List<CollectionSummaryResponse>>().future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body:
                  Row(children: [SizedBox(width: 280, child: CollectionSidebar())]),
            ),
          ),
        ),
      );
      await tester.pump(); // Don't settle — keep in loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no collections', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.text('Create a collection to get started'), findsOneWidget);
    });

    testWidgets('shows Create Collection button in empty state',
        (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      expect(find.text('Create Collection'), findsOneWidget);
    });

    testWidgets('shows collection name when data loaded', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(
        buildSidebar(overrides: [
          courierCollectionsProvider.overrideWith(
            (ref) => Future.value([_stubCollection(name: 'My API')]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('My API'), findsOneWidget);
    });

    testWidgets('shows no-results message when search has no matches',
        (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(
        buildSidebar(overrides: [
          courierCollectionsProvider.overrideWith(
            (ref) => Future.value([_stubCollection(name: 'My API')]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('sidebar_search')), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No results for "zzz"'), findsOneWidget);
    });

    testWidgets('search field updates sidebarSearchQueryProvider',
        (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(sidebarSearchQueryProvider), '');

      await tester.enterText(
          find.byKey(const Key('sidebar_search')), 'Auth');
      await tester.pump();

      expect(container.read(sidebarSearchQueryProvider), 'Auth');
    });

    testWidgets('sort menu opens with sort options', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sort_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Manual order'), findsOneWidget);
      expect(find.text('Alphabetical'), findsOneWidget);
    });

    testWidgets('selecting Alphabetical updates sidebarSortProvider',
        (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CollectionSidebar)),
      );
      expect(container.read(sidebarSortProvider), SidebarSortOrder.manual);

      await tester.tap(find.byKey(const Key('sort_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alphabetical'));
      await tester.pumpAndSettle();

      expect(
          container.read(sidebarSortProvider), SidebarSortOrder.alphabetical);
    });

    testWidgets('new collection button opens create dialog', (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(buildSidebar());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new_collection_button')));
      await tester.pumpAndSettle();

      expect(find.text('New Collection'), findsOneWidget);
      expect(find.byKey(const Key('collection_name_field')), findsOneWidget);
    });

    testWidgets('shows error state when collections fail to load',
        (tester) async {
      setStandardSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courierCollectionsProvider.overrideWith(
              (ref) => Future.error('Network error'),
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

      expect(find.text('Failed to load collections'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
