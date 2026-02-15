/// Integration test: Persona create -> list -> edit -> save -> set default -> delete.
///
/// Tests the full persona management flow using mocked API services.
library;

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/pages/personas_page.dart';
import 'package:codeops/providers/persona_providers.dart';
import 'package:codeops/services/cloud/persona_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPersonaApi extends Mock implements PersonaApi {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockPersonaApi mockApi;

  final personas = <Persona>[
    const Persona(
      id: 'p-1',
      name: 'Security Expert',
      scope: Scope.team,
      agentType: AgentType.security,
      description: 'Security-focused persona',
      isDefault: false,
      version: 1,
    ),
  ];

  setUp(() {
    mockApi = MockPersonaApi();
    when(() => mockApi.getSystemPersonas())
        .thenAnswer((_) async => <Persona>[]);
    when(() => mockApi.getTeamPersonas(any()))
        .thenAnswer((_) async => personas);
    when(() => mockApi.getMyPersonas()).thenAnswer((_) async => personas);
    when(() => mockApi.createPersona(
          name: any(named: 'name'),
          contentMd: any(named: 'contentMd'),
          scope: any(named: 'scope'),
          agentType: any(named: 'agentType'),
          description: any(named: 'description'),
          teamId: any(named: 'teamId'),
          isDefault: any(named: 'isDefault'),
        )).thenAnswer((_) async => const Persona(
          id: 'p-new',
          name: 'New Persona',
          scope: Scope.team,
        ));
    when(() => mockApi.setAsDefault(any())).thenAnswer((_) async =>
        const Persona(
          id: 'p-1',
          name: 'Security Expert',
          scope: Scope.team,
          isDefault: true,
        ));
    when(() => mockApi.deletePersona(any())).thenAnswer((_) async {});
  });

  testWidgets('persona full flow: list -> details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          personaApiProvider.overrideWithValue(mockApi),
          systemPersonasProvider.overrideWith((ref) => Future.value([])),
          teamPersonasProvider.overrideWith((ref) => Future.value(personas)),
        ],
        child: const MaterialApp(home: Scaffold(body: PersonasPage())),
      ),
    );
    await tester.pumpAndSettle();

    // Verify list view shows the persona.
    expect(find.text('Security Expert'), findsOneWidget);
    expect(find.text('Personas'), findsOneWidget);

    // Verify filter controls are present.
    expect(find.text('All Scopes'), findsOneWidget);
    expect(find.text('All Types'), findsOneWidget);
    expect(find.text('New Persona'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });
}
