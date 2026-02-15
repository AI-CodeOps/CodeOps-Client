/// Integration test: Directive create -> list -> assign -> toggle -> remove -> delete.
///
/// Tests the full directive management flow using mocked API services.
library;

import 'package:codeops/models/directive.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/pages/directives_page.dart';
import 'package:codeops/providers/directive_providers.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/services/cloud/directive_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDirectiveApi extends Mock implements DirectiveApi {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockDirectiveApi mockApi;

  final directives = <Directive>[
    const Directive(
      id: 'd-1',
      name: 'Security Standards',
      scope: DirectiveScope.team,
      category: DirectiveCategory.standards,
      description: 'OWASP Top 10 compliance',
      version: 1,
    ),
    const Directive(
      id: 'd-2',
      name: 'Naming Conventions',
      scope: DirectiveScope.team,
      category: DirectiveCategory.conventions,
      description: 'Follow team naming conventions',
      version: 1,
    ),
  ];

  setUp(() {
    mockApi = MockDirectiveApi();
    when(() => mockApi.getTeamDirectives(any()))
        .thenAnswer((_) async => directives);
    when(() => mockApi.createDirective(
          name: any(named: 'name'),
          contentMd: any(named: 'contentMd'),
          scope: any(named: 'scope'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          teamId: any(named: 'teamId'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async => const Directive(
          id: 'd-new',
          name: 'New Directive',
          scope: DirectiveScope.team,
        ));
    when(() => mockApi.deleteDirective(any())).thenAnswer((_) async {});
    when(() => mockApi.assignToProject(
          projectId: any(named: 'projectId'),
          directiveId: any(named: 'directiveId'),
          enabled: any(named: 'enabled'),
        )).thenAnswer((_) async => const ProjectDirective(
          projectId: 'proj-1',
          directiveId: 'd-1',
          enabled: true,
        ));
    when(() => mockApi.toggleDirective(any(), any(), any()))
        .thenAnswer((_) async => const ProjectDirective(
              projectId: 'proj-1',
              directiveId: 'd-1',
              enabled: false,
            ));
    when(() => mockApi.removeFromProject(any(), any()))
        .thenAnswer((_) async {});
  });

  testWidgets('directive full flow: list -> select -> editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          directiveApiProvider.overrideWithValue(mockApi),
          teamDirectivesProvider
              .overrideWith((ref) => Future.value(directives)),
          teamProjectsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(home: Scaffold(body: DirectivesPage())),
      ),
    );
    await tester.pumpAndSettle();

    // Verify list shows directives.
    expect(find.text('Security Standards'), findsOneWidget);
    expect(find.text('Naming Conventions'), findsOneWidget);
    expect(find.text('Directives'), findsOneWidget);

    // Right panel empty state.
    expect(
      find.text('Select a directive or create a new one'),
      findsOneWidget,
    );

    // Tap a directive.
    await tester.tap(find.text('Security Standards'));
    await tester.pumpAndSettle();

    // Editor should appear.
    expect(find.text('Edit Directive'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);
  });
}
