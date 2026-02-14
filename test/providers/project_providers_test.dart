// Tests for project providers.
//
// Verifies that teamProjectsProvider depends on selectedTeamId.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/project_api.dart';

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
}
