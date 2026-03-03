/// Convention management providers for the MCP module.
///
/// Manages project selection, convention document fetching, version history,
/// propagation status across projects, template selection, and editing state
/// for the convention manager page.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcp_models.dart';
import '../models/project.dart';
import 'mcp_providers.dart';
import 'project_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Selected project ID for convention editing.
final conventionProjectIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Whether the convention editor is in edit mode.
final conventionEditModeProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Whether the version history panel is visible.
final conventionHistoryVisibleProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Selected template name (null = no template).
final conventionTemplateProvider =
    StateProvider.autoDispose<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the CONVENTIONS_MD document for the selected project.
final conventionDocumentProvider =
    FutureProvider.autoDispose<ProjectDocumentDetail?>((ref) async {
  final projectId = ref.watch(conventionProjectIdProvider);
  if (projectId == null) return Future.value(null);
  final api = ref.watch(mcpApiProvider);
  try {
    return await api.getDocumentByType(
      projectId: projectId,
      documentType: 'CONVENTIONS_MD',
    );
  } catch (_) {
    return null;
  }
});

/// Fetches version history for a convention document.
final conventionVersionsProvider = FutureProvider.autoDispose
    .family<List<ProjectDocumentVersion>, String>((ref, documentId) async {
  final api = ref.watch(mcpApiProvider);
  final page = await api.getDocumentVersions(documentId, size: 50);
  return page.content;
});

/// Fetches propagation status — for each team project, loads the
/// CONVENTIONS_MD document summary to compare versions.
final conventionPropagationProvider =
    FutureProvider.autoDispose<List<ConventionPropagationEntry>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];

  final projects =
      ref.watch(teamProjectsProvider).whenOrNull(data: (p) => p) ?? [];
  if (projects.isEmpty) return [];

  final api = ref.watch(mcpApiProvider);
  final entries = <ConventionPropagationEntry>[];

  for (final project in projects) {
    try {
      final doc = await api.getDocumentByType(
        projectId: project.id,
        documentType: 'CONVENTIONS_MD',
      );
      entries.add(ConventionPropagationEntry(
        project: project,
        document: doc,
        status: doc.isFlagged == true
            ? PropagationStatus.behind
            : PropagationStatus.current,
      ));
    } catch (_) {
      entries.add(ConventionPropagationEntry(
        project: project,
        status: PropagationStatus.missing,
      ));
    }
  }
  return entries;
});

// ─────────────────────────────────────────────────────────────────────────────
// Propagation Models
// ─────────────────────────────────────────────────────────────────────────────

/// Status of a project's convention document relative to canonical.
enum PropagationStatus {
  /// Project's conventions match the canonical version.
  current,

  /// Project's conventions are out of date.
  behind,

  /// Project has custom conventions diverging from canonical.
  custom,

  /// Project has no convention document.
  missing;

  /// Human-readable display label.
  String get displayName => switch (this) {
        PropagationStatus.current => 'Current',
        PropagationStatus.behind => 'Behind',
        PropagationStatus.custom => 'Custom',
        PropagationStatus.missing => 'Missing',
      };
}

/// Propagation status for a single project.
class ConventionPropagationEntry {
  /// The project.
  final Project project;

  /// The convention document (null if missing).
  final ProjectDocumentDetail? document;

  /// Propagation status.
  final PropagationStatus status;

  /// Creates a [ConventionPropagationEntry].
  const ConventionPropagationEntry({
    required this.project,
    this.document,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Convention Templates
// ─────────────────────────────────────────────────────────────────────────────

/// Built-in convention templates.
const conventionTemplates = <String, String>{
  'AI-First Development': _aiFirstTemplate,
  'Spring Boot Backend': _springBootTemplate,
  'Flutter Frontend': _flutterTemplate,
  'Minimal': _minimalTemplate,
};

const _aiFirstTemplate = '''# CONVENTIONS.md — AI-First Development

## Code Style
- All code must compile and pass tests before commit
- Every public class and method requires documentation
- 100% test coverage ships in the same pass

## AI Collaboration
- AI agents follow CLAUDE.md directives exactly
- Every AI session produces a verification report
- Changes are scoped surgically — only touch what is asked

## Documentation
- Javadoc/TSDoc/DartDoc on all public APIs
- Architecture decisions recorded in ADRs
- OpenAPI spec kept in sync with endpoints
''';

const _springBootTemplate = '''# CONVENTIONS.md — Spring Boot Backend

## Project Structure
- Controller → Service → Repository layering
- DTOs separate from entities
- MapStruct for entity ↔ DTO mapping

## Database
- Hibernate for schema management (no Flyway in development)
- All queries use parameterized statements
- Transactions scoped at the service layer

## Testing
- @WebMvcTest for controller tests
- @DataJpaTest for repository tests
- Integration tests use Testcontainers

## Security
- JWT-based authentication
- Method-level @PreAuthorize annotations
- Input validation on all request bodies
''';

const _flutterTemplate = '''# CONVENTIONS.md — Flutter Frontend

## Architecture
- Riverpod for state management
- GoRouter for navigation
- Feature-first folder structure

## Code Style
- Prefer const constructors
- Widgets decomposed into private _Section classes
- Theme colors from centralized palette

## Testing
- Widget tests for every page
- Provider overrides for test isolation
- Golden tests for critical UI flows

## Naming
- Files: snake_case
- Classes: PascalCase
- Providers: camelCaseProvider suffix
''';

const _minimalTemplate = '''# CONVENTIONS.md

## Code Style
- Follow language-standard formatting
- Write clear, self-documenting code
- Keep functions small and focused

## Testing
- Write tests for all new functionality
- Maintain existing test coverage

## Documentation
- Document public APIs
- Update README for significant changes
''';
