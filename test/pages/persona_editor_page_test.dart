/// Tests for [PersonaEditorPage].
///
/// Covers create/edit modes, form fields, and SYSTEM read-only behavior.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/pages/persona_editor_page.dart';
import 'package:codeops/providers/persona_providers.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/persona_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPersonaApi extends Mock implements PersonaApi {}

class MockApiClient extends Mock implements ApiClient {}

Widget _createWidget({
  String personaId = 'new',
  PersonaApi? mockApi,
}) {
  return ProviderScope(
    overrides: [
      if (mockApi != null)
        personaApiProvider.overrideWithValue(mockApi),
      systemPersonasProvider.overrideWith((ref) => Future.value([])),
      teamPersonasProvider.overrideWith((ref) => Future.value([])),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1400,
          height: 900,
          child: PersonaEditorPage(personaId: personaId),
        ),
      ),
    ),
  );
}

void main() {
  group('PersonaEditorPage', () {
    group('create mode', () {
      testWidgets('shows New Persona title', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.text('New Persona'), findsOneWidget);
      });

      testWidgets('shows form fields', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Name *'), findsOneWidget);
        expect(find.text('Agent Type'), findsOneWidget);
        expect(find.text('Scope'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Default'), findsOneWidget);
      });

      testWidgets('shows Save button', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('shows Test and Export buttons', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
      });

      testWidgets('does not show Delete button in create mode',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsNothing);
      });

      testWidgets('shows back button', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('edit mode', () {
      testWidgets('loads persona data', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockApi = MockPersonaApi();
        when(() => mockApi.getPersona('p-1')).thenAnswer(
          (_) async => const Persona(
            id: 'p-1',
            name: 'My Persona',
            scope: Scope.team,
            description: 'A test',
            contentMd: '## Identity',
            agentType: AgentType.security,
          ),
        );

        await tester.pumpWidget(_createWidget(
          personaId: 'p-1',
          mockApi: mockApi,
        ));
        await tester.pumpAndSettle();

        expect(find.text('My Persona'), findsWidgets);
      });

      testWidgets('shows Delete button for non-system persona',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockApi = MockPersonaApi();
        when(() => mockApi.getPersona('p-1')).thenAnswer(
          (_) async => const Persona(
            id: 'p-1',
            name: 'My Persona',
            scope: Scope.team,
          ),
        );

        await tester.pumpWidget(_createWidget(
          personaId: 'p-1',
          mockApi: mockApi,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
      });
    });

    group('system persona', () {
      testWidgets('shows read-only banner for system scope', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockApi = MockPersonaApi();
        when(() => mockApi.getPersona('p-sys')).thenAnswer(
          (_) async => const Persona(
            id: 'p-sys',
            name: 'System Persona',
            scope: Scope.system,
          ),
        );

        await tester.pumpWidget(_createWidget(
          personaId: 'p-sys',
          mockApi: mockApi,
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('SYSTEM (Read-Only)'), findsOneWidget);
        expect(find.textContaining('read-only'), findsOneWidget);
      });

      testWidgets('hides Save button for system scope', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final mockApi = MockPersonaApi();
        when(() => mockApi.getPersona('p-sys')).thenAnswer(
          (_) async => const Persona(
            id: 'p-sys',
            name: 'System',
            scope: Scope.system,
          ),
        );

        await tester.pumpWidget(_createWidget(
          personaId: 'p-sys',
          mockApi: mockApi,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsNothing);
      });
    });
  });
}
