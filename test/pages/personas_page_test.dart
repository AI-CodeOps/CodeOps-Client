/// Tests for [PersonasPage].
///
/// Covers action bar, filters, data states, and navigation elements.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/pages/personas_page.dart';
import 'package:codeops/providers/persona_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Persona _persona({
  String id = 'p-1',
  String name = 'Test Persona',
  Scope scope = Scope.team,
  AgentType agentType = AgentType.security,
}) {
  return Persona(
    id: id,
    name: name,
    scope: scope,
    agentType: agentType,
    description: 'A test persona',
    updatedAt: DateTime(2025, 1, 1),
  );
}

Widget _createWidget({
  List<Persona> systemPersonas = const [],
  List<Persona> teamPersonas = const [],
}) {
  return ProviderScope(
    overrides: [
      systemPersonasProvider
          .overrideWith((ref) => Future.value(systemPersonas)),
      teamPersonasProvider
          .overrideWith((ref) => Future.value(teamPersonas)),
    ],
    child: const MaterialApp(home: Scaffold(body: PersonasPage())),
  );
}

void main() {
  group('PersonasPage', () {
    testWidgets('shows Personas title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Personas'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows New Persona button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      // May appear in both action bar and empty state.
      expect(find.text('New Persona'), findsWidgets);
    });

    testWidgets('shows Import button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Import'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows empty state when no personas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No personas yet'), findsOneWidget);
    });

    testWidgets('shows persona cards when data available', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(
        teamPersonas: [
          _persona(id: '1', name: 'Alpha'),
          _persona(id: '2', name: 'Beta'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('shows scope filter dropdowns', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Scopes'), findsOneWidget);
      expect(find.text('All Types'), findsOneWidget);
    });
  });
}
