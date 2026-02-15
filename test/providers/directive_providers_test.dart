/// Tests for directive providers.
///
/// Covers all new providers: filtered, search, category/scope filters,
/// and state providers.
library;

import 'package:codeops/models/directive.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/directive_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Directive _directive({
  required String id,
  required String name,
  DirectiveScope scope = DirectiveScope.team,
  DirectiveCategory? category,
  String? description,
}) {
  return Directive(
    id: id,
    name: name,
    scope: scope,
    category: category,
    description: description,
  );
}

void main() {
  group('Directive providers', () {
    group('selectedDirectiveProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(selectedDirectiveProvider), isNull);
      });

      test('can be set', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final directive = _directive(id: '1', name: 'Test');
        container.read(selectedDirectiveProvider.notifier).state = directive;

        expect(container.read(selectedDirectiveProvider)?.id, '1');
      });
    });

    group('directiveSearchQueryProvider', () {
      test('defaults to empty string', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(directiveSearchQueryProvider), '');
      });
    });

    group('directiveCategoryFilterProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(directiveCategoryFilterProvider), isNull);
      });
    });

    group('directiveScopeFilterProvider', () {
      test('defaults to null', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(directiveScopeFilterProvider), isNull);
      });
    });

    group('filteredDirectivesProvider', () {
      test('returns all directives when no filters', () {
        final directives = [
          _directive(id: '1', name: 'Alpha'),
          _directive(id: '2', name: 'Beta'),
        ];

        final container = ProviderContainer(
          overrides: [
            teamDirectivesProvider
                .overrideWith((ref) => Future.value(directives)),
          ],
        );
        addTearDown(container.dispose);

        container.read(teamDirectivesProvider);

        final result = container.read(filteredDirectivesProvider);
        result.whenData((data) {
          expect(data.length, 2);
          // Sorted alphabetically.
          expect(data[0].name, 'Alpha');
          expect(data[1].name, 'Beta');
        });
      });

      test('filters by category', () {
        final directives = [
          _directive(
              id: '1',
              name: 'Arch',
              category: DirectiveCategory.architecture),
          _directive(
              id: '2',
              name: 'Std',
              category: DirectiveCategory.standards),
        ];

        final container = ProviderContainer(
          overrides: [
            teamDirectivesProvider
                .overrideWith((ref) => Future.value(directives)),
          ],
        );
        addTearDown(container.dispose);

        container.read(teamDirectivesProvider);
        container.read(directiveCategoryFilterProvider.notifier).state =
            DirectiveCategory.architecture;

        final result = container.read(filteredDirectivesProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Arch');
        });
      });

      test('filters by scope', () {
        final directives = [
          _directive(id: '1', name: 'Team', scope: DirectiveScope.team),
          _directive(
              id: '2', name: 'Project', scope: DirectiveScope.project),
        ];

        final container = ProviderContainer(
          overrides: [
            teamDirectivesProvider
                .overrideWith((ref) => Future.value(directives)),
          ],
        );
        addTearDown(container.dispose);

        container.read(teamDirectivesProvider);
        container.read(directiveScopeFilterProvider.notifier).state =
            DirectiveScope.project;

        final result = container.read(filteredDirectivesProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Project');
        });
      });

      test('filters by search query', () {
        final directives = [
          _directive(id: '1', name: 'Security Rules'),
          _directive(id: '2', name: 'Code Standards'),
        ];

        final container = ProviderContainer(
          overrides: [
            teamDirectivesProvider
                .overrideWith((ref) => Future.value(directives)),
          ],
        );
        addTearDown(container.dispose);

        container.read(teamDirectivesProvider);
        container.read(directiveSearchQueryProvider.notifier).state =
            'security';

        final result = container.read(filteredDirectivesProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Security Rules');
        });
      });

      test('combines multiple filters', () {
        final directives = [
          _directive(
            id: '1',
            name: 'Security Arch',
            category: DirectiveCategory.architecture,
            scope: DirectiveScope.team,
          ),
          _directive(
            id: '2',
            name: 'Security Std',
            category: DirectiveCategory.standards,
            scope: DirectiveScope.team,
          ),
          _directive(
            id: '3',
            name: 'Perf Arch',
            category: DirectiveCategory.architecture,
            scope: DirectiveScope.project,
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            teamDirectivesProvider
                .overrideWith((ref) => Future.value(directives)),
          ],
        );
        addTearDown(container.dispose);

        container.read(teamDirectivesProvider);
        container.read(directiveCategoryFilterProvider.notifier).state =
            DirectiveCategory.architecture;
        container.read(directiveScopeFilterProvider.notifier).state =
            DirectiveScope.team;
        container.read(directiveSearchQueryProvider.notifier).state =
            'security';

        final result = container.read(filteredDirectivesProvider);
        result.whenData((data) {
          expect(data.length, 1);
          expect(data.first.name, 'Security Arch');
        });
      });
    });
  });
}
