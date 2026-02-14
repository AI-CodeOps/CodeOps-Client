// Tests for finding providers.
//
// Verifies FindingFilters class behavior (defaults, copyWith, hasActiveFilters,
// clearSeverity) and initial state of findingFiltersProvider,
// selectedFindingIdsProvider, and activeFindingProvider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/finding_providers.dart';

void main() {
  group('FindingFilters', () {
    test('default values are correct', () {
      const filters = FindingFilters();

      expect(filters.severity, isNull);
      expect(filters.status, isNull);
      expect(filters.agentType, isNull);
      expect(filters.searchQuery, '');
      expect(filters.sortField, 'severity');
      expect(filters.sortAscending, isTrue);
    });

    test('copyWith updates severity', () {
      const filters = FindingFilters();
      final updated = filters.copyWith(severity: Severity.high);

      expect(updated.severity, Severity.high);
      expect(updated.status, isNull);
      expect(updated.searchQuery, '');
    });

    test('copyWith updates status', () {
      const filters = FindingFilters();
      final updated = filters.copyWith(status: FindingStatus.open);

      expect(updated.status, FindingStatus.open);
    });

    test('copyWith updates agentType', () {
      const filters = FindingFilters();
      final updated = filters.copyWith(agentType: AgentType.security);

      expect(updated.agentType, AgentType.security);
    });

    test('copyWith updates searchQuery', () {
      const filters = FindingFilters();
      final updated = filters.copyWith(searchQuery: 'sql injection');

      expect(updated.searchQuery, 'sql injection');
    });

    test('hasActiveFilters returns false for defaults', () {
      const filters = FindingFilters();

      expect(filters.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters returns true when severity is set', () {
      const filters = FindingFilters(severity: Severity.critical);

      expect(filters.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters returns true when searchQuery is non-empty', () {
      const filters = FindingFilters(searchQuery: 'test');

      expect(filters.hasActiveFilters, isTrue);
    });

    test('clearSeverity resets severity to null', () {
      const filters = FindingFilters(severity: Severity.high);
      final cleared = filters.copyWith(clearSeverity: true);

      expect(cleared.severity, isNull);
    });

    test('clearStatus resets status to null', () {
      const filters = FindingFilters(status: FindingStatus.fixed);
      final cleared = filters.copyWith(clearStatus: true);

      expect(cleared.status, isNull);
    });

    test('clearAgentType resets agentType to null', () {
      const filters = FindingFilters(agentType: AgentType.security);
      final cleared = filters.copyWith(clearAgentType: true);

      expect(cleared.agentType, isNull);
    });
  });

  group('Finding state providers', () {
    test('findingFiltersProvider initial state has no active filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filters = container.read(findingFiltersProvider);

      expect(filters.severity, isNull);
      expect(filters.status, isNull);
      expect(filters.agentType, isNull);
      expect(filters.searchQuery, '');
      expect(filters.hasActiveFilters, isFalse);
    });

    test('selectedFindingIdsProvider initial state is empty set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedIds = container.read(selectedFindingIdsProvider);

      expect(selectedIds, isEmpty);
      expect(selectedIds, isA<Set<String>>());
    });

    test('activeFindingProvider initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final active = container.read(activeFindingProvider);

      expect(active, isNull);
    });

    test('findingFiltersProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(findingFiltersProvider.notifier).state =
          const FindingFilters(severity: Severity.critical);

      final filters = container.read(findingFiltersProvider);
      expect(filters.severity, Severity.critical);
      expect(filters.hasActiveFilters, isTrue);
    });

    test('selectedFindingIdsProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFindingIdsProvider.notifier).state = {'f1', 'f2'};

      final selectedIds = container.read(selectedFindingIdsProvider);
      expect(selectedIds, containsAll(['f1', 'f2']));
      expect(selectedIds.length, 2);
    });

    test('findingSeverityFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(findingSeverityFilterProvider), isNull);
    });

    test('findingStatusFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(findingStatusFilterProvider), isNull);
    });

    test('findingAgentFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(findingAgentFilterProvider), isNull);
    });
  });
}
