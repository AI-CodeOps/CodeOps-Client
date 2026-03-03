/// Context viewer providers for the MCP module.
///
/// Manages the simulated session context payload, project/developer/environment
/// selection, context section health indicators, and assembled context data
/// for the Context Viewer page.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcp_enums.dart';
import '../models/mcp_models.dart';
import 'mcp_providers.dart';
import 'project_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Selected project ID for context simulation.
final contextProjectIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Selected developer profile ID for context simulation.
final contextDeveloperIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Selected environment for context simulation.
final contextEnvironmentProvider =
    StateProvider.autoDispose<McpEnvironment>((ref) => McpEnvironment.local);

/// Whether context simulation has been triggered.
final contextSimulatedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Whether to show the raw JSON view.
final contextRawJsonProvider =
    StateProvider.autoDispose<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Context Section Model
// ─────────────────────────────────────────────────────────────────────────────

/// Health status of a context section.
enum ContextSectionHealth {
  /// Data present and fresh.
  healthy,

  /// Data present but stale.
  stale,

  /// Missing or errored.
  missing,

  /// Not applicable for this project.
  notApplicable;

  /// Human-readable display label.
  String get displayName => switch (this) {
        ContextSectionHealth.healthy => 'Healthy',
        ContextSectionHealth.stale => 'Stale',
        ContextSectionHealth.missing => 'Missing',
        ContextSectionHealth.notApplicable => 'N/A',
      };
}

/// A single section within the assembled context payload.
class ContextSection {
  /// Section title (e.g., "Persona", "Conventions").
  final String title;

  /// Section health status.
  final ContextSectionHealth health;

  /// Section content as a map for JSON serialization.
  final Map<String, dynamic> data;

  /// Number of items in this section.
  final int itemCount;

  /// Estimated size in bytes.
  final int sizeBytes;

  /// Creates a [ContextSection].
  const ContextSection({
    required this.title,
    required this.health,
    required this.data,
    this.itemCount = 0,
    this.sizeBytes = 0,
  });
}

/// The assembled context payload for a simulated session.
class AssembledContext {
  /// Context sections in display order.
  final List<ContextSection> sections;

  /// Total payload size in bytes.
  final int totalSizeBytes;

  /// Estimated token count (~4 chars per token).
  final int estimatedTokens;

  /// The full payload as a JSON-encodable map.
  final Map<String, dynamic> payload;

  /// Creates an [AssembledContext].
  const AssembledContext({
    required this.sections,
    required this.totalSizeBytes,
    required this.estimatedTokens,
    required this.payload,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Context Assembly Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Assembles the simulated context payload from all data sources.
///
/// Fetches documents, sessions, profiles, and produces a preview of what
/// the AI agent would receive on session init.
final contextAssemblyProvider =
    FutureProvider.autoDispose<AssembledContext?>((ref) async {
  final simulated = ref.watch(contextSimulatedProvider);
  if (!simulated) return null;

  final projectId = ref.watch(contextProjectIdProvider);
  final developerId = ref.watch(contextDeveloperIdProvider);
  final environment = ref.watch(contextEnvironmentProvider);
  final teamId = ref.watch(selectedTeamIdProvider);

  if (projectId == null || teamId == null) return null;

  final api = ref.watch(mcpApiProvider);

  // Fetch data in parallel
  final results = await Future.wait([
    api.getProjectDocuments(projectId: projectId).catchError((_) => <ProjectDocument>[]),
    api.getSessionHistory(projectId: projectId, limit: 5).catchError((_) => <McpSession>[]),
    api.getTeamProfiles(teamId: teamId).catchError((_) => <DeveloperProfile>[]),
  ]);

  final docs = results[0] as List<ProjectDocument>;
  final sessions = results[1] as List<McpSession>;
  final profiles = results[2] as List<DeveloperProfile>;

  // Find selected developer
  final developer = developerId != null
      ? profiles.where((p) => p.id == developerId).firstOrNull
      : null;

  // Get project name
  final projectAsync = ref.watch(projectProvider(projectId));
  final projectName = projectAsync.whenOrNull(data: (p) => p.name) ?? projectId;

  // Build sections
  final sections = <ContextSection>[];
  final payload = <String, dynamic>{};

  // 1. Persona
  final personaData = {
    'agentType': 'claude',
    'teamId': teamId,
    'developer': developer?.displayName ?? developer?.userDisplayName ?? 'Unknown',
    'environment': environment.toJson(),
  };
  sections.add(ContextSection(
    title: 'Persona',
    health: developer != null
        ? ContextSectionHealth.healthy
        : ContextSectionHealth.missing,
    data: personaData,
    itemCount: 1,
    sizeBytes: _estimateSize(personaData),
  ));
  payload['persona'] = personaData;

  // 2. Conventions
  final conventionsDoc = docs
      .where((d) => d.documentType == DocumentType.conventionsMd)
      .firstOrNull;
  final conventionsData = {
    'present': conventionsDoc != null,
    'lastUpdated': conventionsDoc?.updatedAt?.toIso8601String(),
    'lastAuthor': conventionsDoc?.lastAuthorType?.displayName,
    'isFlagged': conventionsDoc?.isFlagged ?? false,
  };
  sections.add(ContextSection(
    title: 'Conventions',
    health: _docHealth(conventionsDoc),
    data: conventionsData,
    itemCount: conventionsDoc != null ? 1 : 0,
    sizeBytes: _estimateSize(conventionsData),
  ));
  payload['conventions'] = conventionsData;

  // 3. Project Documents
  final docsData = {
    'totalDocuments': docs.length,
    'documents': docs
        .map((d) => {
              'type': d.documentType?.displayName,
              'name': d.customName ?? d.documentType?.displayName,
              'lastUpdated': d.updatedAt?.toIso8601String(),
              'lastAuthor': d.lastAuthorType?.displayName,
              'isFlagged': d.isFlagged ?? false,
            })
        .toList(),
  };
  sections.add(ContextSection(
    title: 'Project Documents',
    health: docs.isEmpty
        ? ContextSectionHealth.missing
        : docs.any((d) => d.isFlagged == true)
            ? ContextSectionHealth.stale
            : ContextSectionHealth.healthy,
    data: docsData,
    itemCount: docs.length,
    sizeBytes: _estimateSize(docsData),
  ));
  payload['projectDocuments'] = docsData;

  // 4. Ecosystem Context
  final ecosystemData = {
    'projectName': projectName,
    'environment': environment.displayName,
    'note': 'Registry services, ports, and dependencies for this project',
  };
  sections.add(ContextSection(
    title: 'Ecosystem Context',
    health: ContextSectionHealth.healthy,
    data: ecosystemData,
    itemCount: 1,
    sizeBytes: _estimateSize(ecosystemData),
  ));
  payload['ecosystemContext'] = ecosystemData;

  // 5. Secret References
  final secretsData = {
    'note': 'Secret paths available via Vault (values masked)',
    'environment': environment.displayName,
  };
  sections.add(ContextSection(
    title: 'Secret References',
    health: ContextSectionHealth.notApplicable,
    data: secretsData,
    itemCount: 0,
    sizeBytes: _estimateSize(secretsData),
  ));
  payload['secretReferences'] = secretsData;

  // 6. Team Directives
  final claudeDoc = docs
      .where((d) => d.documentType == DocumentType.claudeMd)
      .firstOrNull;
  final directivesData = {
    'claudeMdPresent': claudeDoc != null,
    'lastUpdated': claudeDoc?.updatedAt?.toIso8601String(),
    'isFlagged': claudeDoc?.isFlagged ?? false,
  };
  sections.add(ContextSection(
    title: 'Team Directives',
    health: _docHealth(claudeDoc),
    data: directivesData,
    itemCount: claudeDoc != null ? 1 : 0,
    sizeBytes: _estimateSize(directivesData),
  ));
  payload['teamDirectives'] = directivesData;

  // 7. Recent Sessions
  final sessionsData = {
    'count': sessions.length,
    'sessions': sessions
        .map((s) => {
              'status': s.status?.displayName,
              'project': s.projectName,
              'developer': s.developerName,
              'environment': s.environment?.displayName,
              'startedAt': s.startedAt?.toIso8601String(),
              'toolCalls': s.totalToolCalls,
            })
        .toList(),
  };
  sections.add(ContextSection(
    title: 'Recent Sessions',
    health: sessions.isEmpty
        ? ContextSectionHealth.notApplicable
        : ContextSectionHealth.healthy,
    data: sessionsData,
    itemCount: sessions.length,
    sizeBytes: _estimateSize(sessionsData),
  ));
  payload['recentSessions'] = sessionsData;

  // 8. Team Discussion
  final discussionData = {
    'note': 'Recent Relay messages from project channel',
    'available': false,
  };
  sections.add(ContextSection(
    title: 'Team Discussion',
    health: ContextSectionHealth.notApplicable,
    data: discussionData,
    itemCount: 0,
    sizeBytes: _estimateSize(discussionData),
  ));
  payload['teamDiscussion'] = discussionData;

  // 9. Container Status
  final containerData = {
    'note': 'Running containers for project services from Fleet',
    'environment': environment.displayName,
  };
  sections.add(ContextSection(
    title: 'Container Status',
    health: ContextSectionHealth.notApplicable,
    data: containerData,
    itemCount: 0,
    sizeBytes: _estimateSize(containerData),
  ));
  payload['containerStatus'] = containerData;

  // Calculate totals
  final totalBytes =
      sections.fold<int>(0, (sum, s) => sum + s.sizeBytes);
  final estimatedTokens = (totalBytes / 4).ceil();

  // 10. Payload Size (metadata)
  payload['_meta'] = {
    'totalSizeBytes': totalBytes,
    'estimatedTokens': estimatedTokens,
    'sectionCount': sections.length,
    'assembledAt': DateTime.now().toUtc().toIso8601String(),
  };

  return AssembledContext(
    sections: sections,
    totalSizeBytes: totalBytes,
    estimatedTokens: estimatedTokens,
    payload: payload,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Estimates JSON size in bytes.
int _estimateSize(Map<String, dynamic> data) {
  try {
    return jsonEncode(data).length;
  } catch (_) {
    return 0;
  }
}

/// Computes health for a document section.
ContextSectionHealth _docHealth(ProjectDocument? doc) {
  if (doc == null) return ContextSectionHealth.missing;
  if (doc.isFlagged == true) return ContextSectionHealth.stale;

  final updated = doc.updatedAt;
  if (updated == null) return ContextSectionHealth.stale;

  final age = DateTime.now().difference(updated);
  if (age.inHours < 48) return ContextSectionHealth.healthy;
  return ContextSectionHealth.stale;
}
