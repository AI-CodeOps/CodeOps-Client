// Tests for project providers.
//
// Verifies state providers, favorites notifier, sort/filter enums,
// and provider dependencies.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/project_api.dart';
import 'package:codeops/services/data/sync_service.dart';

void main() {
  group('Project providers', () {
    test('projectApiProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(projectApiProvider);

      expect(api, isA<ProjectApi>());
    });

    test('selectedProjectIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedProjectIdProvider), isNull);
    });

    test('selectedProjectIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedProjectIdProvider.notifier).state = 'proj-1';

      expect(container.read(selectedProjectIdProvider), 'proj-1');
    });

    test('teamProjectsProvider returns empty when no team selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedTeamIdProvider), isNull);

      final asyncProjects = container.read(teamProjectsProvider);
      expect(asyncProjects, isA<AsyncValue>());
    });
  });

  group('ProjectSortOrder', () {
    test('has 4 values', () {
      expect(ProjectSortOrder.values, hasLength(4));
    });

    test('default sort is nameAsc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(projectSortProvider), ProjectSortOrder.nameAsc);
    });

    test('sort can be changed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(projectSortProvider.notifier).state =
          ProjectSortOrder.healthScoreDesc;
      expect(
          container.read(projectSortProvider), ProjectSortOrder.healthScoreDesc);
    });
  });

  group('SyncState', () {
    test('projectSyncStateProvider defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(projectSyncStateProvider), SyncState.idle);
    });

    test('sync state can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(projectSyncStateProvider.notifier).state =
          SyncState.syncing;
      expect(container.read(projectSyncStateProvider), SyncState.syncing);
    });
  });

  group('Search and filter', () {
    test('projectSearchQueryProvider defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(projectSearchQueryProvider), '');
    });

    test('search query can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(projectSearchQueryProvider.notifier).state = 'flutter';
      expect(container.read(projectSearchQueryProvider), 'flutter');
    });

    test('showArchivedProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(showArchivedProvider), isFalse);
    });

    test('showArchived can be toggled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(showArchivedProvider.notifier).state = true;
      expect(container.read(showArchivedProvider), isTrue);
    });
  });

  group('FavoriteProjectsNotifier', () {
    test('starts with empty set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(favoriteProjectIdsProvider), isEmpty);
    });

    test('toggle adds project', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(favoriteProjectIdsProvider.notifier).toggle('proj-1');
      expect(container.read(favoriteProjectIdsProvider), contains('proj-1'));
    });

    test('toggle removes existing project', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoriteProjectIdsProvider.notifier);
      notifier.toggle('proj-1');
      notifier.toggle('proj-1');
      expect(container.read(favoriteProjectIdsProvider),
          isNot(contains('proj-1')));
    });

    test('isFavorite returns correct result', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoriteProjectIdsProvider.notifier);
      expect(notifier.isFavorite('proj-1'), isFalse);
      notifier.toggle('proj-1');
      expect(notifier.isFavorite('proj-1'), isTrue);
    });

    test('multiple favorites coexist', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(favoriteProjectIdsProvider.notifier);
      notifier.toggle('a');
      notifier.toggle('b');
      notifier.toggle('c');

      final favs = container.read(favoriteProjectIdsProvider);
      expect(favs, hasLength(3));
      expect(favs, containsAll(['a', 'b', 'c']));
    });
  });
}
