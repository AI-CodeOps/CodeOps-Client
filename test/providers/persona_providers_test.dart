/// Tests for persona providers.
///
/// Covers all new providers: filtered, search, scope/agentType filters,
/// deduplication, and state providers.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/providers/persona_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Persona _persona({
  required String id,
  required String name,
  Scope scope = Scope.team,
  AgentType? agentType,
  String? description,
  bool? isDefault,
}) {
  return Persona(
    id: id,
    name: name,
    scope: scope,
    agentType: agentType,
    description: description,
    isDefault: isDefault,
  );
}

void main() {
  group('Persona providers', () {
    group('selectedPersonaProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(selectedPersonaProvider), isNull);
      });

      test('can be set', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final persona = _persona(id: '1', name: 'Test');
        container.read(selectedPersonaProvider.notifier).state = persona;

        expect(container.read(selectedPersonaProvider)?.id, '1');
      });
    });

    group('personaSearchQueryProvider', () {
      test('defaults to empty string', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(personaSearchQueryProvider), '');
      });
    });

    group('personaScopeFilterProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(personaScopeFilterProvider), isNull);
      });
    });

    group('personaAgentTypeFilterProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(personaAgentTypeFilterProvider), isNull);
      });
    });

    group('filteredPersonasProvider', () {
      test('combines system and team personas with deduplication',
          () async {
        final systemPersonas = [
          _persona(id: '1', name: 'System A', scope: Scope.system),
          _persona(id: '2', name: 'System B', scope: Scope.system),
        ];
        final teamPersonas = [
          _persona(id: '2', name: 'System B Dup', scope: Scope.system),
          _persona(id: '3', name: 'Team A', scope: Scope.team),
        ];

        final container = ProviderContainer(
          overrides: [
            systemPersonasProvider
                .overrideWith((ref) => Future.value(systemPersonas)),
            teamPersonasProvider
                .overrideWith((ref) => Future.value(teamPersonas)),
          ],
        );
        addTearDown(container.dispose);

        // Wait for futures to resolve.
        await container.read(systemPersonasProvider.future);
        await container.read(teamPersonasProvider.future);

        final result = container.read(filteredPersonasProvider);

        result.when(
          loading: () => fail('Should not be loading'),
          error: (e, _) => fail('Should not be error: $e'),
          data: (personas) {
            // Should have 3 (deduplicated by id).
            expect(personas.length, 3);
            // System first, then team.
            expect(personas[0].scope, Scope.system);
            expect(personas[1].scope, Scope.system);
            expect(personas[2].scope, Scope.team);
          },
        );
      });

      test('filters by scope', () async {
        final personas = [
          _persona(id: '1', name: 'System', scope: Scope.system),
          _persona(id: '2', name: 'Team', scope: Scope.team),
        ];

        final container = ProviderContainer(
          overrides: [
            systemPersonasProvider
                .overrideWith((ref) => Future.value(personas)),
            teamPersonasProvider.overrideWith((ref) => Future.value([])),
          ],
        );
        addTearDown(container.dispose);

        await container.read(systemPersonasProvider.future);
        await container.read(teamPersonasProvider.future);
        container.read(personaScopeFilterProvider.notifier).state = Scope.team;

        final result = container.read(filteredPersonasProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Team');
        });
      });

      test('filters by agent type', () async {
        final personas = [
          _persona(
              id: '1',
              name: 'Sec',
              scope: Scope.team,
              agentType: AgentType.security),
          _persona(
              id: '2',
              name: 'Perf',
              scope: Scope.team,
              agentType: AgentType.performance),
        ];

        final container = ProviderContainer(
          overrides: [
            systemPersonasProvider.overrideWith((ref) => Future.value([])),
            teamPersonasProvider
                .overrideWith((ref) => Future.value(personas)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(systemPersonasProvider.future);
        await container.read(teamPersonasProvider.future);
        container.read(personaAgentTypeFilterProvider.notifier).state =
            AgentType.security;

        final result = container.read(filteredPersonasProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Sec');
        });
      });

      test('filters by search query', () async {
        final personas = [
          _persona(id: '1', name: 'Security Expert', scope: Scope.team),
          _persona(id: '2', name: 'Performance Guru', scope: Scope.team),
        ];

        final container = ProviderContainer(
          overrides: [
            systemPersonasProvider.overrideWith((ref) => Future.value([])),
            teamPersonasProvider
                .overrideWith((ref) => Future.value(personas)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(systemPersonasProvider.future);
        await container.read(teamPersonasProvider.future);
        container.read(personaSearchQueryProvider.notifier).state = 'security';

        final result = container.read(filteredPersonasProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Security Expert');
        });
      });

      test('returns loading when providers are loading', () {
        final container = ProviderContainer(
          overrides: [
            systemPersonasProvider
                .overrideWith((ref) => Future.value(<Persona>[])),
            teamPersonasProvider
                .overrideWith((ref) => Future.value(<Persona>[])),
          ],
        );
        addTearDown(container.dispose);

        // Don't read the async providers — they stay in loading state.
        final result = container.read(filteredPersonasProvider);
        expect(result is AsyncLoading, isTrue);
      });
    });
  });
}
