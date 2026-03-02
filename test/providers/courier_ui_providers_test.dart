// Unit tests for courier_ui_providers.dart
//
// Tests that all StateProviders start with correct defaults and that
// state mutations work correctly on RequestTab and pane-width providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/providers/courier_ui_providers.dart';

void main() {
  group('courier_ui_providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ── openRequestTabsProvider ──────────────────────────────────────────────

    test('openRequestTabsProvider starts empty', () {
      expect(container.read(openRequestTabsProvider), isEmpty);
    });

    test('openRequestTabsProvider accepts new tabs', () {
      const tab = RequestTab(
        id: 't1',
        requestId: 'req-1',
        name: 'GET /users',
        method: CourierHttpMethod.get,
        url: 'http://localhost/users',
      );

      container.read(openRequestTabsProvider.notifier).state = [tab];
      final tabs = container.read(openRequestTabsProvider);

      expect(tabs, hasLength(1));
      expect(tabs.first.id, 't1');
      expect(tabs.first.method, CourierHttpMethod.get);
      expect(tabs.first.isDirty, isFalse);
      expect(tabs.first.isNew, isFalse);
    });

    // ── activeRequestTabProvider ─────────────────────────────────────────────

    test('activeRequestTabProvider starts null', () {
      expect(container.read(activeRequestTabProvider), isNull);
    });

    test('activeRequestTabProvider updates correctly', () {
      container.read(activeRequestTabProvider.notifier).state = 'tab-123';
      expect(container.read(activeRequestTabProvider), 'tab-123');
    });

    // ── sidebarWidthProvider ─────────────────────────────────────────────────

    test('sidebarWidthProvider starts at 280', () {
      expect(container.read(sidebarWidthProvider), 280.0);
    });

    test('sidebarWidthProvider updates to new value', () {
      container.read(sidebarWidthProvider.notifier).state = 320.0;
      expect(container.read(sidebarWidthProvider), 320.0);
    });

    // ── responsePaneWidthProvider ────────────────────────────────────────────

    test('responsePaneWidthProvider starts at 400', () {
      expect(container.read(responsePaneWidthProvider), 400.0);
    });

    // ── activeEnvironmentIdProvider ──────────────────────────────────────────

    test('activeEnvironmentIdProvider starts null', () {
      expect(container.read(activeEnvironmentIdProvider), isNull);
    });

    test('activeEnvironmentIdProvider accepts an environment ID', () {
      container.read(activeEnvironmentIdProvider.notifier).state = 'env-abc';
      expect(container.read(activeEnvironmentIdProvider), 'env-abc');
    });

    test('activeEnvironmentIdProvider can be cleared back to null', () {
      container.read(activeEnvironmentIdProvider.notifier).state = 'env-abc';
      container.read(activeEnvironmentIdProvider.notifier).state = null;
      expect(container.read(activeEnvironmentIdProvider), isNull);
    });

    // ── consoleVisibleProvider ───────────────────────────────────────────────

    test('consoleVisibleProvider starts false', () {
      expect(container.read(consoleVisibleProvider), isFalse);
    });

    test('consoleVisibleProvider toggles to true and back', () {
      container.read(consoleVisibleProvider.notifier).state = true;
      expect(container.read(consoleVisibleProvider), isTrue);

      container.read(consoleVisibleProvider.notifier).state = false;
      expect(container.read(consoleVisibleProvider), isFalse);
    });

    // ── responsePaneCollapsedProvider ────────────────────────────────────────

    test('responsePaneCollapsedProvider starts false', () {
      expect(container.read(responsePaneCollapsedProvider), isFalse);
    });

    // ── RequestTab copyWith ──────────────────────────────────────────────────

    test('RequestTab.copyWith preserves unchanged fields', () {
      const tab = RequestTab(
        id: 'tab-1',
        requestId: 'req-1',
        name: 'POST /api',
        method: CourierHttpMethod.post,
        url: 'http://localhost/api',
        isDirty: false,
        isNew: true,
      );

      final updated = tab.copyWith(isDirty: true);

      expect(updated.id, 'tab-1');
      expect(updated.requestId, 'req-1');
      expect(updated.name, 'POST /api');
      expect(updated.method, CourierHttpMethod.post);
      expect(updated.url, 'http://localhost/api');
      expect(updated.isDirty, isTrue);
      expect(updated.isNew, isTrue);
    });

    test('RequestTab.copyWith can update name and URL independently', () {
      const tab = RequestTab(
        id: 'tab-2',
        name: 'Old Name',
        method: CourierHttpMethod.get,
        url: 'http://old.url',
      );

      final updated = tab.copyWith(name: 'New Name', url: 'http://new.url');

      expect(updated.name, 'New Name');
      expect(updated.url, 'http://new.url');
      expect(updated.id, 'tab-2');
    });

    // ── expandedNodesProvider ────────────────────────────────────────────────

    test('expandedNodesProvider starts empty', () {
      expect(container.read(expandedNodesProvider), isEmpty);
    });

    test('expandedNodesProvider accepts node IDs', () {
      container.read(expandedNodesProvider.notifier).state = {'col-1', 'col-2'};
      expect(container.read(expandedNodesProvider), containsAll(['col-1', 'col-2']));
    });

    test('expandedNodesProvider can remove a node ID', () {
      container.read(expandedNodesProvider.notifier).state = {'col-1', 'col-2'};
      final nodes = container.read(expandedNodesProvider);
      container.read(expandedNodesProvider.notifier).state =
          Set.from(nodes)..remove('col-1');
      expect(container.read(expandedNodesProvider), isNot(contains('col-1')));
      expect(container.read(expandedNodesProvider), contains('col-2'));
    });

    // ── selectedNodeIdProvider ───────────────────────────────────────────────

    test('selectedNodeIdProvider starts null', () {
      expect(container.read(selectedNodeIdProvider), isNull);
    });

    test('selectedNodeIdProvider updates to a collection ID', () {
      container.read(selectedNodeIdProvider.notifier).state = 'col-abc';
      expect(container.read(selectedNodeIdProvider), 'col-abc');
    });

    test('selectedNodeIdProvider can be cleared back to null', () {
      container.read(selectedNodeIdProvider.notifier).state = 'col-abc';
      container.read(selectedNodeIdProvider.notifier).state = null;
      expect(container.read(selectedNodeIdProvider), isNull);
    });

    // ── sidebarSortProvider ──────────────────────────────────────────────────

    test('sidebarSortProvider starts as manual', () {
      expect(container.read(sidebarSortProvider), SidebarSortOrder.manual);
    });

    test('sidebarSortProvider can switch to alphabetical', () {
      container.read(sidebarSortProvider.notifier).state =
          SidebarSortOrder.alphabetical;
      expect(
          container.read(sidebarSortProvider), SidebarSortOrder.alphabetical);
    });

    test('sidebarSortProvider can switch back to manual', () {
      container.read(sidebarSortProvider.notifier).state =
          SidebarSortOrder.alphabetical;
      container.read(sidebarSortProvider.notifier).state =
          SidebarSortOrder.manual;
      expect(container.read(sidebarSortProvider), SidebarSortOrder.manual);
    });
  });
}
