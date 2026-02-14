/// Riverpod providers for directive data.
///
/// Exposes the [DirectiveApi] service, team directives,
/// and project directive assignments.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directive.dart';
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
