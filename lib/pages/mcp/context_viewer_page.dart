/// MCP context viewer page.
///
/// Displays at `/mcp/context`. Lets users preview exactly what context
/// an AI agent would receive on session init. Configuration panel at top
/// (project, developer, environment selectors + simulate button), then
/// accordion sections showing each context area with health indicators.
/// Toggle between structured view and raw JSON.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/mcp_enums.dart';
import '../../providers/mcp_context_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/scribe/scribe_editor.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP context viewer page.
class ContextViewerPage extends ConsumerWidget {
  /// Creates a [ContextViewerPage].
  const ContextViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view context.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          const SizedBox(height: 20),
          _ConfigPanel(teamId: teamId),
          const SizedBox(height: 20),
          _ContextDisplay(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/mcp'),
          child: const Text(
            'Dashboard',
            style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Context Viewer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Preview what an AI agent receives on session init',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Configuration Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ConfigPanel extends ConsumerWidget {
  final String teamId;

  const _ConfigPanel({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(teamProjectsProvider);
    final profilesAsync = ref.watch(mcpTeamProfilesProvider(teamId));
    final selectedProject = ref.watch(contextProjectIdProvider);
    final selectedDeveloper = ref.watch(contextDeveloperIdProvider);
    final selectedEnvironment = ref.watch(contextEnvironmentProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Configuration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // Project selector
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Project',
                        style: TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textSecondary)),
                    const SizedBox(height: 4),
                    projectsAsync.when(
                      loading: () => const SizedBox(
                        height: 36,
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CodeOpsColors.primary),
                        ),
                      ),
                      error: (_, __) => const Text('Error',
                          style: TextStyle(
                              color: CodeOpsColors.error, fontSize: 12)),
                      data: (projects) => DropdownButton<String?>(
                        value: selectedProject,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Select Project',
                            style: TextStyle(fontSize: 12)),
                        style: const TextStyle(
                            fontSize: 12,
                            color: CodeOpsColors.textPrimary),
                        dropdownColor: CodeOpsColors.surface,
                        items: [
                          for (final p in projects)
                            DropdownMenuItem(
                                value: p.id, child: Text(p.name)),
                        ],
                        onChanged: (v) => ref
                            .read(contextProjectIdProvider.notifier)
                            .state = v,
                      ),
                    ),
                  ],
                ),
              ),
              // Developer selector
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Developer Profile',
                        style: TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textSecondary)),
                    const SizedBox(height: 4),
                    profilesAsync.when(
                      loading: () => const SizedBox(
                        height: 36,
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CodeOpsColors.primary),
                        ),
                      ),
                      error: (_, __) => const Text('Error',
                          style: TextStyle(
                              color: CodeOpsColors.error, fontSize: 12)),
                      data: (profiles) => DropdownButton<String?>(
                        value: selectedDeveloper,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Select Developer',
                            style: TextStyle(fontSize: 12)),
                        style: const TextStyle(
                            fontSize: 12,
                            color: CodeOpsColors.textPrimary),
                        dropdownColor: CodeOpsColors.surface,
                        items: [
                          for (final p in profiles)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                  p.displayName ?? p.userDisplayName ?? 'Dev'),
                            ),
                        ],
                        onChanged: (v) => ref
                            .read(contextDeveloperIdProvider.notifier)
                            .state = v,
                      ),
                    ),
                  ],
                ),
              ),
              // Environment selector
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Environment',
                        style: TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButton<McpEnvironment>(
                      value: selectedEnvironment,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textPrimary),
                      dropdownColor: CodeOpsColors.surface,
                      items: [
                        for (final env in McpEnvironment.values)
                          DropdownMenuItem(
                            value: env,
                            child: Text(env.displayName),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(contextEnvironmentProvider.notifier)
                              .state = v;
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Simulate button
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: selectedProject != null
                      ? () {
                          ref.read(contextSimulatedProvider.notifier).state =
                              true;
                          ref.invalidate(contextAssemblyProvider);
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Simulate Session Init'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CodeOpsColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context Display
// ─────────────────────────────────────────────────────────────────────────────

class _ContextDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulated = ref.watch(contextSimulatedProvider);
    if (!simulated) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: const Center(
          child: Text(
            'Select a project and click "Simulate Session Init" to preview context',
            style: TextStyle(
                color: CodeOpsColors.textTertiary, fontSize: 13),
          ),
        ),
      );
    }

    final contextAsync = ref.watch(contextAssemblyProvider);
    final showRawJson = ref.watch(contextRawJsonProvider);

    return contextAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: CodeOpsColors.primary),
        ),
      ),
      error: (e, _) => ErrorPanel.fromException(e, onRetry: () {
        ref.invalidate(contextAssemblyProvider);
      }),
      data: (assembled) {
        if (assembled == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text('No context assembled',
                  style: TextStyle(
                      color: CodeOpsColors.textTertiary, fontSize: 13)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar: Raw JSON toggle, payload stats, copy
            _DisplayToolbar(assembled: assembled),
            const SizedBox(height: 12),
            if (showRawJson)
              _RawJsonView(payload: assembled.payload)
            else
              _SectionAccordions(sections: assembled.sections),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display Toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayToolbar extends ConsumerWidget {
  final AssembledContext assembled;

  const _DisplayToolbar({required this.assembled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRawJson = ref.watch(contextRawJsonProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          // Payload size stats
          _StatChip(
            icon: Icons.data_object,
            label: _formatBytes(assembled.totalSizeBytes),
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.token,
            label: '~${_formatNumber(assembled.estimatedTokens)} tokens',
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.layers_outlined,
            label: '${assembled.sections.length} sections',
          ),
          const Spacer(),
          // Raw JSON toggle
          FilterChip(
            label: Text(
              showRawJson ? 'Structured' : 'Raw JSON',
              style: const TextStyle(fontSize: 11),
            ),
            selected: showRawJson,
            onSelected: (v) =>
                ref.read(contextRawJsonProvider.notifier).state = v,
            selectedColor:
                CodeOpsColors.primary.withValues(alpha: 0.2),
            backgroundColor: CodeOpsColors.surface,
            side: BorderSide(
              color: showRawJson
                  ? CodeOpsColors.primary
                  : CodeOpsColors.border,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          // Copy button
          IconButton(
            onPressed: () {
              final json =
                  const JsonEncoder.withIndent('  ').convert(assembled.payload);
              Clipboard.setData(ClipboardData(text: json));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Context payload copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy Payload',
            color: CodeOpsColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CodeOpsColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Accordions
// ─────────────────────────────────────────────────────────────────────────────

class _SectionAccordions extends StatelessWidget {
  final List<ContextSection> sections;

  const _SectionAccordions({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionPanelList.radio(
          elevation: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < sections.length; i++)
              ExpansionPanelRadio(
                value: i,
                canTapOnHeader: true,
                headerBuilder: (_, isExpanded) =>
                    _SectionHeader(section: sections[i]),
                body: _SectionBody(section: sections[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final ContextSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Health indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _healthColor(section.health),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              section.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          // Item count badge
          if (section.itemCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${section.itemCount}',
                style: const TextStyle(
                  fontSize: 10,
                  color: CodeOpsColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Size
          Text(
            _formatBytes(section.sizeBytes),
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final ContextSection section;

  const _SectionBody({required this.section});

  @override
  Widget build(BuildContext context) {
    final json =
        const JsonEncoder.withIndent('  ').convert(section.data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: CodeOpsColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health label
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _healthColor(section.health).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.health.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _healthColor(section.health),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // JSON content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: SelectableText(
              json,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Raw JSON View
// ─────────────────────────────────────────────────────────────────────────────

class _RawJsonView extends StatelessWidget {
  final Map<String, dynamic> payload;

  const _RawJsonView({required this.payload});

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ').convert(payload);

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: ScribeEditor(
        content: json,
        language: 'json',
        readOnly: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a color for [ContextSectionHealth].
Color _healthColor(ContextSectionHealth health) => switch (health) {
      ContextSectionHealth.healthy => CodeOpsColors.success,
      ContextSectionHealth.stale => CodeOpsColors.warning,
      ContextSectionHealth.missing => CodeOpsColors.error,
      ContextSectionHealth.notApplicable => CodeOpsColors.textTertiary,
    };

/// Formats bytes for display.
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
}

/// Formats a number with comma separators.
String _formatNumber(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
