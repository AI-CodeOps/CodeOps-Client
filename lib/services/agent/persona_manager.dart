/// Assembles complete agent prompts by layering persona, directives, and job
/// context into a single markdown document.
///
/// The layering order is:
/// 1. Persona (team override or built-in fallback)
/// 2. Team directives
/// 3. Project directives
/// 4. Job context (project name, branch, mode, specs, Jira data)
/// 5. Report format instructions
library;

import 'package:flutter/services.dart' show rootBundle;

import '../../models/enums.dart';
import '../cloud/directive_api.dart';
import '../cloud/persona_api.dart';
import '../logging/log_service.dart';

// ---------------------------------------------------------------------------
// PersonaManager
// ---------------------------------------------------------------------------

/// Assembles complete agent prompts by layering persona content, team and
/// project directives, and contextual job metadata.
///
/// Prompts are returned as a single markdown string ready to be passed to the
/// Claude Code subprocess as the system prompt.
class PersonaManager {
  final PersonaApi _personaApi;
  final DirectiveApi _directiveApi;

  /// Creates a [PersonaManager].
  ///
  /// Requires a [PersonaApi] for loading team persona overrides and a
  /// [DirectiveApi] for fetching team and project directives.
  PersonaManager({
    required PersonaApi personaApi,
    required DirectiveApi directiveApi,
  })  : _personaApi = personaApi,
        _directiveApi = directiveApi;

  /// Assembles a complete prompt for a single agent run.
  ///
  /// [agentType] determines which built-in persona to load as a fallback.
  /// [teamId] and [projectId] scope the directive lookups.
  /// [mode] is the current job mode (audit, compliance, etc.).
  /// [projectName] and [branch] describe the target codebase.
  /// [additionalContext] is free-form text appended to the context section.
  /// [jiraTicketData] is raw Jira ticket content for bug-investigate mode.
  /// [specReferences] is a list of specification names/paths for compliance.
  /// [agentFileContents] is pre-loaded markdown from [AgentFiles] entries,
  /// inserted between directives and job context. Optional — null means
  /// no agent-specific file content is injected.
  ///
  /// Returns a fully-assembled markdown string.
  Future<String> assemblePrompt({
    required AgentType agentType,
    required String teamId,
    required String projectId,
    required JobMode mode,
    required String projectName,
    required String branch,
    String? additionalContext,
    String? jiraTicketData,
    List<String>? specReferences,
    List<String>? agentFileContents,
  }) async {
    log.i('PersonaManager', 'Assembling prompt (agent=${agentType.name}, mode=${mode.name})');
    final sections = <String>[];

    // 1. Persona (team override or built-in fallback).
    final persona = await _resolvePersona(teamId, agentType);
    sections.add(persona);

    // 2. Directives (team + project).
    final directives = await loadDirectives(teamId, projectId);
    if (directives.isNotEmpty) {
      sections.add(directives);
    }

    // 2.5. Agent-specific file content (from AgentFiles DB entries).
    if (agentFileContents != null && agentFileContents.isNotEmpty) {
      final fileBuffer = StringBuffer();
      fileBuffer.writeln('## Agent Configuration Files');
      fileBuffer.writeln();
      for (final content in agentFileContents) {
        if (content.isNotEmpty) {
          fileBuffer.writeln(content);
          fileBuffer.writeln();
        }
      }
      sections.add(fileBuffer.toString().trim());
    }

    // 3. Job context.
    sections.add(_buildJobContext(
      projectName: projectName,
      branch: branch,
      mode: mode,
      agentType: agentType,
      additionalContext: additionalContext,
      jiraTicketData: jiraTicketData,
      specReferences: specReferences,
    ));

    // 4. Report format instructions.
    sections.add(_reportFormatInstructions);

    final result = sections.join('\n\n---\n\n');
    log.d('PersonaManager', 'Prompt assembled (${sections.length} sections, ${result.length} chars)');
    return result;
  }

  /// Loads the built-in persona markdown for [agentType] from bundled assets.
  ///
  /// Assets are expected at `assets/personas/agent-{kebab-type}.md`.
  Future<String> loadBuiltInPersona(AgentType agentType) async {
    final kebab = _agentTypeToKebab(agentType);
    final assetPath = 'assets/personas/agent-$kebab.md';
    return rootBundle.loadString(assetPath);
  }

  /// Attempts to load the team's default persona for [agentType].
  ///
  /// Returns the persona's `contentMd` if a team default exists, or `null`
  /// if no override is configured or the request fails (e.g. 404).
  Future<String?> loadTeamPersona(
    String teamId,
    AgentType agentType,
  ) async {
    try {
      final persona = await _personaApi.getTeamDefaultPersona(
        teamId,
        agentType,
      );
      final content = persona.contentMd;
      return (content != null && content.isNotEmpty) ? content : null;
    } catch (_) {
      // No team default configured, or network error — fall back to built-in.
      return null;
    }
  }

  /// Loads and concatenates all applicable directives for the given
  /// [teamId] and [projectId].
  ///
  /// Team-scoped directives are fetched first, followed by project-scoped
  /// enabled directives. Each directive's `contentMd` is rendered under a
  /// level-3 heading with the directive name and category.
  Future<String> loadDirectives(String teamId, String projectId) async {
    final buffer = StringBuffer();

    // Team directives.
    try {
      final teamDirectives = await _directiveApi.getTeamDirectives(teamId);
      for (final directive in teamDirectives) {
        final content = directive.contentMd;
        if (content != null && content.isNotEmpty) {
          final category = directive.category?.displayName ?? 'General';
          buffer.writeln('### Directive: ${directive.name} [$category]');
          buffer.writeln();
          buffer.writeln(content);
          buffer.writeln();
        }
      }
    } catch (_) {
      // Team directives unavailable — continue without them.
    }

    // Project-specific enabled directives.
    try {
      final projectDirectives =
          await _directiveApi.getProjectEnabledDirectives(projectId);
      for (final directive in projectDirectives) {
        final content = directive.contentMd;
        if (content != null && content.isNotEmpty) {
          final category = directive.category?.displayName ?? 'General';
          buffer.writeln(
            '### Project Directive: ${directive.name} [$category]',
          );
          buffer.writeln();
          buffer.writeln(content);
          buffer.writeln();
        }
      }
    } catch (_) {
      // Project directives unavailable — continue without them.
    }

    return buffer.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Resolves the persona content: tries team override first, falls back to
  /// built-in.
  Future<String> _resolvePersona(
    String teamId,
    AgentType agentType,
  ) async {
    final teamPersona = await loadTeamPersona(teamId, agentType);
    if (teamPersona != null) return teamPersona;
    return loadBuiltInPersona(agentType);
  }

  /// Builds the job-context markdown section.
  String _buildJobContext({
    required String projectName,
    required String branch,
    required JobMode mode,
    required AgentType agentType,
    String? additionalContext,
    String? jiraTicketData,
    List<String>? specReferences,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('## Job Context');
    buffer.writeln();
    buffer.writeln('| Field | Value |');
    buffer.writeln('|-------|-------|');
    buffer.writeln('| **Project** | $projectName |');
    buffer.writeln('| **Branch** | `$branch` |');
    buffer.writeln('| **Mode** | ${mode.displayName} |');
    buffer.writeln('| **Agent** | ${agentType.displayName} |');

    if (specReferences != null && specReferences.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### Specification References');
      buffer.writeln();
      for (final spec in specReferences) {
        buffer.writeln('- $spec');
      }
    }

    if (jiraTicketData != null && jiraTicketData.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### Jira Ticket Data');
      buffer.writeln();
      buffer.writeln(jiraTicketData);
    }

    if (additionalContext != null && additionalContext.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### Additional Context');
      buffer.writeln();
      buffer.writeln(additionalContext);
    }

    return buffer.toString().trim();
  }

  /// Converts an [AgentType] enum value to its kebab-case string
  /// representation for asset path lookup.
  ///
  /// Examples:
  /// - `AgentType.codeQuality` -> `"code-quality"`
  /// - `AgentType.security` -> `"security"`
  /// - `AgentType.uiUx` -> `"ui-ux"`
  /// - `AgentType.apiContract` -> `"api-contract"`
  static String _agentTypeToKebab(AgentType type) => switch (type) {
        AgentType.security => 'security',
        AgentType.codeQuality => 'code-quality',
        AgentType.buildHealth => 'build-health',
        AgentType.completeness => 'completeness',
        AgentType.apiContract => 'api-contract',
        AgentType.testCoverage => 'test-coverage',
        AgentType.uiUx => 'ui-ux',
        AgentType.documentation => 'documentation',
        AgentType.database => 'database',
        AgentType.performance => 'performance',
        AgentType.dependency => 'dependency',
        AgentType.architecture => 'architecture',
      };

  /// Standardized report format instructions appended to every assembled
  /// prompt so that agent output is parsable by [ReportParser].
  static const String _reportFormatInstructions = '''
## Report Format Instructions

You MUST structure your output as a markdown report with the following sections:

### Metadata Header

Start with these fields on separate lines at the top:

```
**Project:** <project name>
**Date:** <YYYY-MM-DD>
**Agent:** <agent type>
**Overall:** <PASS|WARN|FAIL>
**Score:** <0-100>
```

### Executive Summary

A `## Executive Summary` section with a concise 2-3 sentence overview.

### Findings

A `## Findings` section. Each finding is a level-3 heading with severity:

```
### [CRITICAL] Finding title here
```

Valid severity tags: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`.

Under each finding heading, include these labeled fields:

```
**File:** path/to/file.ext
**Line:** 42
**Description:** Detailed description of the issue.
**Recommendation:** Specific actionable recommendation.
**Effort:** S|M|L|XL
**Evidence:** Code snippet or log output demonstrating the issue.
```

All fields except the heading are optional but recommended.

### Metrics

A `## Metrics` section with a markdown table:

```
| Metric | Value |
|--------|-------|
| Files Reviewed | 42 |
| Total Findings | 7 |
| Critical | 1 |
| High | 2 |
| Medium | 3 |
| Low | 1 |
| Score | 72 |
```''';
}
