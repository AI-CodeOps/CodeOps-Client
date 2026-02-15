/// Riverpod providers for directive data.
///
/// Exposes the [DirectiveApi] service, team directives,
/// and project directive assignments.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directive.dart';
import '../models/enums.dart';
import '../services/cloud/directive_api.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

/// Provides [DirectiveApi] for directive endpoints.
final directiveApiProvider = Provider<DirectiveApi>(
  (ref) => DirectiveApi(ref.watch(apiClientProvider)),
);

/// Fetches all directives for the selected team.
final teamDirectivesProvider = FutureProvider<List<Directive>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final directiveApi = ref.watch(directiveApiProvider);
  return directiveApi.getTeamDirectives(teamId);
});

/// Fetches directive assignments for a specific project.
final projectDirectivesProvider =
    FutureProvider.family<List<ProjectDirective>, String>(
  (ref, projectId) async {
    final directiveApi = ref.watch(directiveApiProvider);
    return directiveApi.getProjectDirectiveAssignments(projectId);
  },
);

// ---------------------------------------------------------------------------
// New providers for directives page
// ---------------------------------------------------------------------------

/// Fetches enabled directives for a project.
final enabledDirectivesProvider =
    FutureProvider.family<List<Directive>, String>((ref, projectId) async {
  final directiveApi = ref.watch(directiveApiProvider);
  return directiveApi.getProjectEnabledDirectives(projectId);
});

/// The currently selected directive in the list view.
final selectedDirectiveProvider = StateProvider<Directive?>((ref) => null);

/// Search query for filtering the directives list.
final directiveSearchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter for the directives list.
final directiveCategoryFilterProvider =
    StateProvider<DirectiveCategory?>((ref) => null);

/// Scope filter for the directives list.
final directiveScopeFilterProvider =
    StateProvider<DirectiveScope?>((ref) => null);

/// Directives filtered by search query, category, and scope.
final filteredDirectivesProvider = Provider<AsyncValue<List<Directive>>>((ref) {
  final directivesAsync = ref.watch(teamDirectivesProvider);
  final query = ref.watch(directiveSearchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(directiveCategoryFilterProvider);
  final scopeFilter = ref.watch(directiveScopeFilterProvider);

  return directivesAsync.whenData((directives) {
    return _applyDirectiveFilters(directives, query, categoryFilter, scopeFilter);
  });
});

List<Directive> _applyDirectiveFilters(
  List<Directive> directives,
  String query,
  DirectiveCategory? categoryFilter,
  DirectiveScope? scopeFilter,
) {
  var filtered = directives;

  // Filter by category.
  if (categoryFilter != null) {
    filtered = filtered.where((d) => d.category == categoryFilter).toList();
  }

  // Filter by scope.
  if (scopeFilter != null) {
    filtered = filtered.where((d) => d.scope == scopeFilter).toList();
  }

  // Filter by search query.
  if (query.isNotEmpty) {
    filtered = filtered.where((d) {
      return d.name.toLowerCase().contains(query) ||
          (d.description?.toLowerCase().contains(query) ?? false) ||
          (d.category?.displayName.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Sort alphabetically.
  filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return filtered;
}
