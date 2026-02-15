/// Tests for [DirectivesPage].
///
/// Covers master-detail layout, filters, inline editor, and empty states.
library;

import 'package:codeops/models/directive.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/pages/directives_page.dart';
import 'package:codeops/providers/directive_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/widgets/shared/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Directive _directive({
  String id = 'd-1',
  String name = 'Test Directive',
  DirectiveScope scope = DirectiveScope.team,
  DirectiveCategory? category = DirectiveCategory.standards,
  String? description = 'A test directive',
}) {
  return Directive(
    id: id,
    name: name,
    scope: scope,
    category: category,
    description: description,
    updatedAt: DateTime(2025, 1, 1),
  );
}

Widget _createWidget({
  List<Directive> directives = const [],
}) {
  return ProviderScope(
    overrides: [
      teamDirectivesProvider
          .overrideWith((ref) => Future.value(directives)),
      teamProjectsProvider.overrideWith((ref) => Future.value([])),
    ],
    child: const MaterialApp(home: Scaffold(body: DirectivesPage())),
  );
}

void main() {
  group('DirectivesPage', () {
    testWidgets('shows Directives title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Directives'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows New button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('shows category and scope dropdowns', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('All Scopes'), findsOneWidget);
    });

    testWidgets('shows empty state when no directives', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Override the filtered provider directly to bypass async issues.
      await tester.pumpWidget(ProviderScope(
        overrides: [
          teamDirectivesProvider
              .overrideWith((ref) => Future.value(<Directive>[])),
          teamProjectsProvider.overrideWith((ref) => Future.value([])),
          filteredDirectivesProvider.overrideWithValue(
            const AsyncValue.data(<Directive>[]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DirectivesPage())),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows right panel empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Select a directive or create a new one'),
        findsOneWidget,
      );
    });

    testWidgets('shows directive cards when data available', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        directives: [
          _directive(id: '1', name: 'Alpha'),
          _directive(id: '2', name: 'Beta'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('shows editor when directive is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        directives: [_directive(name: 'Test Dir')],
      ));
      await tester.pumpAndSettle();

      // Tap the directive card.
      await tester.tap(find.text('Test Dir'));
      await tester.pumpAndSettle();

      // Editor should show.
      expect(find.text('Edit Directive'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsWidgets);
    });
  });
}
