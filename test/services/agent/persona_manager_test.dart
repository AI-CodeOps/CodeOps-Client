// Tests for PersonaManager persona resolution and directive loading.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/models/directive.dart';
import 'package:codeops/services/agent/persona_manager.dart';
import 'package:codeops/services/cloud/directive_api.dart';
import 'package:codeops/services/cloud/persona_api.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockPersonaApi extends Mock implements PersonaApi {}

class MockDirectiveApi extends Mock implements DirectiveApi {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _teamId = 'team-111';
const _projectId = 'project-222';

/// Creates a [Persona] with sensible defaults for testing.
Persona _makePersona({
  String id = 'persona-1',
  String name = 'Test Persona',
  AgentType? agentType = AgentType.security,
  String? contentMd = '# Security Persona\n\nYou are a security auditor.',
  Scope scope = Scope.team,
  String? teamId = _teamId,
  bool? isDefault = true,
}) {
  return Persona(
    id: id,
    name: name,
    agentType: agentType,
    contentMd: contentMd,
    scope: scope,
    teamId: teamId,
    isDefault: isDefault,
  );
}

/// Creates a [Directive] with sensible defaults for testing.
Directive _makeDirective({
  String id = 'directive-1',
  String name = 'Security Standards',
  String? contentMd = 'Always use HTTPS.',
  DirectiveCategory? category,
  DirectiveScope scope = DirectiveScope.team,
  String? teamId = _teamId,
  String? projectId,
}) {
  return Directive(
    id: id,
    name: name,
    contentMd: contentMd,
    category: category,
    scope: scope,
    teamId: teamId,
    projectId: projectId,
  );
}

void main() {
  late MockPersonaApi mockPersonaApi;
  late MockDirectiveApi mockDirectiveApi;
  late PersonaManager manager;

  setUp(() {
    mockPersonaApi = MockPersonaApi();
    mockDirectiveApi = MockDirectiveApi();
    manager = PersonaManager(
      personaApi: mockPersonaApi,
      directiveApi: mockDirectiveApi,
    );
  });

  // -----------------------------------------------------------------------
  // loadTeamPersona
  // -----------------------------------------------------------------------

  group('loadTeamPersona', () {
    test('returns contentMd when team persona exists', () async {
      final persona = _makePersona(
        contentMd: 'You are a strict security reviewer.',
      );
      when(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.security,
          )).thenAnswer((_) async => persona);

      final result = await manager.loadTeamPersona(
        _teamId,
        AgentType.security,
      );

      expect(result, 'You are a strict security reviewer.');
      verify(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.security,
          )).called(1);
    });

    test('returns null when API throws (e.g. 404)', () async {
      when(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.security,
          )).thenThrow(Exception('404 Not Found'));

      final result = await manager.loadTeamPersona(
        _teamId,
        AgentType.security,
      );

      expect(result, isNull);
    });

    test('returns null when contentMd is empty string', () async {
      final persona = _makePersona(contentMd: '');
      when(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.codeQuality,
          )).thenAnswer((_) async => persona);

      final result = await manager.loadTeamPersona(
        _teamId,
        AgentType.codeQuality,
      );

      expect(result, isNull);
    });

    test('returns null when contentMd is null', () async {
      final persona = _makePersona(contentMd: null);
      when(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.security,
          )).thenAnswer((_) async => persona);

      final result = await manager.loadTeamPersona(
        _teamId,
        AgentType.security,
      );

      expect(result, isNull);
    });

    test('works with different agent types', () async {
      final persona = _makePersona(
        agentType: AgentType.architecture,
        contentMd: 'Architecture persona content.',
      );
      when(() => mockPersonaApi.getTeamDefaultPersona(
            _teamId,
            AgentType.architecture,
          )).thenAnswer((_) async => persona);

      final result = await manager.loadTeamPersona(
        _teamId,
        AgentType.architecture,
      );

      expect(result, 'Architecture persona content.');
    });
  });

  // -----------------------------------------------------------------------
  // loadDirectives
  // -----------------------------------------------------------------------

  group('loadDirectives', () {
    test('concatenates team and project directives', () async {
      final teamDirectives = [
        _makeDirective(
          id: 'td-1',
          name: 'Security Standards',
          contentMd: 'Always use HTTPS.',
          category: DirectiveCategory.standards,
        ),
      ];
      final projectDirectives = [
        _makeDirective(
          id: 'pd-1',
          name: 'API Conventions',
          contentMd: 'Use REST naming.',
          category: DirectiveCategory.conventions,
          scope: DirectiveScope.project,
          projectId: _projectId,
        ),
      ];

      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => teamDirectives);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => projectDirectives);

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, contains('### Directive: Security Standards [Standards]'));
      expect(result, contains('Always use HTTPS.'));
      expect(
        result,
        contains('### Project Directive: API Conventions [Conventions]'),
      );
      expect(result, contains('Use REST naming.'));
    });

    test('handles team directives API failure gracefully', () async {
      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenThrow(Exception('Network error'));
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => [
                _makeDirective(
                  id: 'pd-1',
                  name: 'Project Rule',
                  contentMd: 'Do the thing.',
                  scope: DirectiveScope.project,
                  projectId: _projectId,
                ),
              ]);

      final result = await manager.loadDirectives(_teamId, _projectId);

      // Team directives section should be absent; project directives present.
      expect(result, isNot(contains('### Directive:')));
      expect(result, contains('### Project Directive: Project Rule'));
      expect(result, contains('Do the thing.'));
    });

    test('handles project directives API failure gracefully', () async {
      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => [
                _makeDirective(
                  id: 'td-1',
                  name: 'Team Rule',
                  contentMd: 'Follow the standard.',
                  category: DirectiveCategory.standards,
                ),
              ]);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenThrow(Exception('Server error'));

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, contains('### Directive: Team Rule [Standards]'));
      expect(result, contains('Follow the standard.'));
      expect(result, isNot(contains('### Project Directive:')));
    });

    test('returns empty string when no directives exist', () async {
      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => []);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => []);

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, isEmpty);
    });

    test('skips directives with null contentMd', () async {
      final teamDirectives = [
        _makeDirective(
          id: 'td-1',
          name: 'Empty Directive',
          contentMd: null,
        ),
        _makeDirective(
          id: 'td-2',
          name: 'Real Directive',
          contentMd: 'Actual content here.',
          category: DirectiveCategory.architecture,
        ),
      ];

      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => teamDirectives);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => []);

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, isNot(contains('Empty Directive')));
      expect(
        result,
        contains('### Directive: Real Directive [Architecture]'),
      );
      expect(result, contains('Actual content here.'));
    });

    test('skips directives with empty string contentMd', () async {
      final teamDirectives = [
        _makeDirective(
          id: 'td-1',
          name: 'Blank Directive',
          contentMd: '',
        ),
      ];

      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => teamDirectives);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => []);

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, isEmpty);
    });

    test('defaults category to General when category is null', () async {
      final teamDirectives = [
        _makeDirective(
          id: 'td-1',
          name: 'Uncategorized Rule',
          contentMd: 'Some rule.',
          category: null,
        ),
      ];

      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => teamDirectives);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => []);

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(
        result,
        contains('### Directive: Uncategorized Rule [General]'),
      );
    });

    test('returns empty when both APIs throw', () async {
      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenThrow(Exception('Timeout'));
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenThrow(Exception('Timeout'));

      final result = await manager.loadDirectives(_teamId, _projectId);

      expect(result, isEmpty);
    });

    test('handles multiple team and project directives', () async {
      final teamDirectives = [
        _makeDirective(
          id: 'td-1',
          name: 'Rule A',
          contentMd: 'Content A.',
          category: DirectiveCategory.standards,
        ),
        _makeDirective(
          id: 'td-2',
          name: 'Rule B',
          contentMd: 'Content B.',
          category: DirectiveCategory.conventions,
        ),
      ];
      final projectDirectives = [
        _makeDirective(
          id: 'pd-1',
          name: 'Proj Rule X',
          contentMd: 'Content X.',
          category: DirectiveCategory.context,
          scope: DirectiveScope.project,
          projectId: _projectId,
        ),
        _makeDirective(
          id: 'pd-2',
          name: 'Proj Rule Y',
          contentMd: 'Content Y.',
          category: DirectiveCategory.other,
          scope: DirectiveScope.project,
          projectId: _projectId,
        ),
      ];

      when(() => mockDirectiveApi.getTeamDirectives(_teamId))
          .thenAnswer((_) async => teamDirectives);
      when(() => mockDirectiveApi.getProjectEnabledDirectives(_projectId))
          .thenAnswer((_) async => projectDirectives);

      final result = await manager.loadDirectives(_teamId, _projectId);

      // Team directives appear first
      expect(result, contains('### Directive: Rule A [Standards]'));
      expect(result, contains('### Directive: Rule B [Conventions]'));
      // Then project directives
      expect(
        result,
        contains('### Project Directive: Proj Rule X [Context]'),
      );
      expect(
        result,
        contains('### Project Directive: Proj Rule Y [Other]'),
      );

      // Verify ordering: team before project
      final teamIdx = result.indexOf('### Directive: Rule A');
      final projIdx = result.indexOf('### Project Directive: Proj Rule X');
      expect(teamIdx, lessThan(projIdx));
    });
  });
}
