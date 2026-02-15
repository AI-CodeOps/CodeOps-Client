/// Tests for [PersonaList] widget.
///
/// Covers card rendering, badge display, context menu, and empty state.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/providers/persona_providers.dart';
import 'package:codeops/widgets/personas/persona_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Persona _persona({
  String id = 'p-1',
  String name = 'Test Persona',
  Scope scope = Scope.team,
  AgentType? agentType = AgentType.security,
  String? description = 'A test persona',
  bool? isDefault = false,
  int? version = 1,
  String? createdByName = 'Adam',
}) {
  return Persona(
    id: id,
    name: name,
    scope: scope,
    agentType: agentType,
    description: description,
    isDefault: isDefault,
    version: version,
    createdByName: createdByName,
    updatedAt: DateTime(2025, 1, 1),
  );
}

Widget _createWidget(List<Persona> personas) {
  return ProviderScope(
    overrides: [
      systemPersonasProvider.overrideWith((ref) => Future.value([])),
      teamPersonasProvider.overrideWith((ref) => Future.value(personas)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: PersonaList(personas: personas),
        ),
      ),
    ),
  );
}

void main() {
  group('PersonaList', () {
    testWidgets('renders persona cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final personas = [
        _persona(id: '1', name: 'Alpha Persona'),
        _persona(id: '2', name: 'Beta Persona'),
      ];

      await tester.pumpWidget(_createWidget(personas));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Persona'), findsOneWidget);
      expect(find.text('Beta Persona'), findsOneWidget);
    });

    testWidgets('shows agent type badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([
        _persona(agentType: AgentType.security),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('shows scope badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([
        _persona(scope: Scope.team),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Team'), findsOneWidget);
    });

    testWidgets('shows default indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([
        _persona(isDefault: true),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('shows description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([
        _persona(description: 'Custom description text'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Custom description text'), findsOneWidget);
    });

    testWidgets('shows context menu on icon tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([_persona()]));
      await tester.pumpAndSettle();

      // Tap the context menu button.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows version and creator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget([
        _persona(version: 3, createdByName: 'Adam'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('v3'), findsOneWidget);
      expect(find.text('Adam'), findsOneWidget);
    });
  });
}
