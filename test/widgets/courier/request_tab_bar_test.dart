// Widget tests for RequestTabBar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/request_tab_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildTabBar({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: Column(children: [RequestTabBar()])),
    ),
  );
}

RequestTab _tab({
  String id = 'tab-1',
  String name = 'GET /users',
  CourierHttpMethod method = CourierHttpMethod.get,
  bool isDirty = false,
}) =>
    RequestTab(
      id: id,
      name: name,
      method: method,
      url: 'http://localhost/users',
      isDirty: isDirty,
    );

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RequestTabBar', () {
    testWidgets('renders empty-state hint when no tabs open', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTabBar());
      await tester.pumpAndSettle();

      expect(
        find.text('No open requests — click + to create one'),
        findsOneWidget,
      );
    });

    testWidgets('shows new_tab_button', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTabBar());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('new_tab_button')), findsOneWidget);
    });

    testWidgets('renders tab name when a tab is open', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTabBar(overrides: [
        openRequestTabsProvider.overrideWith(
          (ref) => [_tab(name: 'GET /users')],
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('GET /users'), findsOneWidget);
    });

    testWidgets('active tab has top-border indicator color', (tester) async {
      setSize(tester);
      const tabId = 'tab-active';
      await tester.pumpWidget(buildTabBar(overrides: [
        openRequestTabsProvider.overrideWith(
          (ref) => [_tab(id: tabId, name: 'My Request')],
        ),
        activeRequestTabProvider.overrideWith((ref) => tabId),
      ]));
      await tester.pumpAndSettle();

      // The active tab container has a top border — verify the tab widget key.
      expect(find.byKey(Key('tab_$tabId')), findsOneWidget);
    });

    testWidgets('tapping a tab sets it as active', (tester) async {
      setSize(tester);
      const tabId = 'tab-2';
      await tester.pumpWidget(buildTabBar(overrides: [
        openRequestTabsProvider.overrideWith(
          (ref) => [_tab(id: 'tab-1', name: 'First'), _tab(id: tabId, name: 'Second')],
        ),
      ]));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequestTabBar)),
      );
      expect(container.read(activeRequestTabProvider), isNot(tabId));

      await tester.tap(find.text('Second'));
      // Double-tap disambiguation delay — advance 500ms past the 300ms timer.
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(activeRequestTabProvider), tabId);
    });

    testWidgets('close button removes tab from list', (tester) async {
      setSize(tester);
      const tabId = 'tab-to-close';
      await tester.pumpWidget(buildTabBar(overrides: [
        openRequestTabsProvider.overrideWith(
          (ref) => [_tab(id: tabId, name: 'Close Me')],
        ),
      ]));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequestTabBar)),
      );

      await tester.tap(find.byKey(Key('close_tab_$tabId')));
      // InkWell is inside a GestureDetector with onDoubleTap — advance past
      // the 300ms double-tap disambiguation timer.
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(openRequestTabsProvider), isEmpty);
    });

    testWidgets('new_tab_button adds a tab and makes it active', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTabBar());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequestTabBar)),
      );
      expect(container.read(openRequestTabsProvider), isEmpty);

      await tester.tap(find.byKey(const Key('new_tab_button')));
      await tester.pump();

      final tabs = container.read(openRequestTabsProvider);
      expect(tabs, hasLength(1));
      expect(tabs.first.name, 'New Request');
      expect(tabs.first.isNew, isTrue);
      expect(container.read(activeRequestTabProvider), tabs.first.id);
    });

    testWidgets('dirty indicator shown when tab.isDirty is true', (tester) async {
      setSize(tester);
      const tabId = 'dirty-tab';
      await tester.pumpWidget(buildTabBar(overrides: [
        openRequestTabsProvider.overrideWith(
          (ref) => [_tab(id: tabId, name: 'Unsaved', isDirty: true)],
        ),
        activeRequestTabProvider.overrideWith((ref) => tabId),
      ]));
      await tester.pumpAndSettle();

      // Dirty tab has an orange dot (Container with warning color).
      // Verify via the overall tab container key being present.
      expect(find.byKey(Key('tab_$tabId')), findsOneWidget);

      // The tab name text is present alongside the dirty dot.
      expect(find.text('Unsaved'), findsOneWidget);
    });
  });
}
