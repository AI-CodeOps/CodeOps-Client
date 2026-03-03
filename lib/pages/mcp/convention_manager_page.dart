/// MCP convention manager page.
///
/// Displays at `/mcp/conventions` with a ScribeEditor for editing
/// CONVENTIONS.md, a toolbar with project selector, version indicator,
/// save/history/diff/publish buttons, a slide-in version history panel,
/// propagation status across projects, and convention templates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/mcp_convention_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/scribe/scribe_editor.dart';
import '../../widgets/shared/empty_state.dart';

/// The MCP convention manager page.
class ConventionManagerPage extends ConsumerStatefulWidget {
  /// Creates a [ConventionManagerPage].
  const ConventionManagerPage({super.key});

  @override
  ConsumerState<ConventionManagerPage> createState() =>
      _ConventionManagerPageState();
}

class _ConventionManagerPageState extends ConsumerState<ConventionManagerPage> {
  String _editorContent = '';
  bool _hasUnsavedChanges = false;

  void _refresh() {
    ref.invalidate(conventionDocumentProvider);
    ref.invalidate(conventionPropagationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to manage conventions.',
      );
    }

    final historyVisible = ref.watch(conventionHistoryVisibleProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onRefresh: _refresh),
          const SizedBox(height: 20),
          // Toolbar
          _Toolbar(
            editorContent: _editorContent,
            hasUnsavedChanges: _hasUnsavedChanges,
            onSaved: () => setState(() => _hasUnsavedChanges = false),
          ),
          const SizedBox(height: 12),
          // Main content area
          SizedBox(
            height: MediaQuery.of(context).size.height - 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editor pane
                Expanded(
                  flex: 3,
                  child: _EditorPane(
                    editorContent: _editorContent,
                    onContentChanged: (v) {
                      setState(() {
                        _editorContent = v;
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                ),
                // Version history panel (slide-in)
                if (historyVisible) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 320,
                    child: _VersionHistoryPanel(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Propagation status
          const _PropagationSection(),
          const SizedBox(height: 24),
          // Templates
          const _TemplateSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;

  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/mcp'),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Convention Manager',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: CodeOpsColors.textSecondary),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _Toolbar extends ConsumerWidget {
  final String editorContent;
  final bool hasUnsavedChanges;
  final VoidCallback onSaved;

  const _Toolbar({
    required this.editorContent,
    required this.hasUnsavedChanges,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(teamProjectsProvider);
    final selectedProjectId = ref.watch(conventionProjectIdProvider);
    final editMode = ref.watch(conventionEditModeProvider);
    final historyVisible = ref.watch(conventionHistoryVisibleProvider);
    final docAsync = ref.watch(conventionDocumentProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          // Project selector
          SizedBox(
            width: 220,
            child: projectsAsync.when(
              loading: () => const SizedBox(
                height: 36,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              error: (_, __) => const Text('Error',
                  style: TextStyle(color: CodeOpsColors.error, fontSize: 12)),
              data: (projects) => DropdownButton<String?>(
                value: selectedProjectId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select Project',
                    style: TextStyle(
                        fontSize: 13, color: CodeOpsColors.textSecondary)),
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
                dropdownColor: CodeOpsColors.surface,
                items: [
                  for (final p in projects)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    ),
                ],
                onChanged: (id) {
                  ref.read(conventionProjectIdProvider.notifier).state = id;
                  ref.read(conventionEditModeProvider.notifier).state = false;
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Version indicator
          if (docAsync.hasValue && docAsync.value != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'v${docAsync.value!.versions?.length ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Word count
            Builder(builder: (context) {
              final content = docAsync.value!.currentContent ?? '';
              final wordCount = content
                  .split(RegExp(r'\s+'))
                  .where((w) => w.isNotEmpty)
                  .length;
              return Text(
                '$wordCount words',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              );
            }),
          ],
          const Spacer(),
          // Edit toggle
          IconButton(
            onPressed: selectedProjectId == null
                ? null
                : () {
                    ref.read(conventionEditModeProvider.notifier).state =
                        !editMode;
                  },
            icon: Icon(
              editMode ? Icons.visibility : Icons.edit_outlined,
              size: 18,
            ),
            tooltip: editMode ? 'View Mode' : 'Edit Mode',
            color: CodeOpsColors.textSecondary,
          ),
          // Save button
          if (editMode && hasUnsavedChanges)
            TextButton.icon(
              onPressed: () async {
                final doc = docAsync.value;
                if (doc?.id == null) return;
                final api = ref.read(mcpApiProvider);
                await api.updateDocument(doc!.id!, {
                  'content': editorContent,
                  'authorType': 'HUMAN',
                  'changeDescription': 'Updated via Convention Manager',
                });
                ref.invalidate(conventionDocumentProvider);
                onSaved();
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          // History toggle
          IconButton(
            onPressed: selectedProjectId == null
                ? null
                : () {
                    ref
                        .read(conventionHistoryVisibleProvider.notifier)
                        .state = !historyVisible;
                  },
            icon: const Icon(Icons.history, size: 18),
            tooltip: 'Version History',
            color: historyVisible
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor Pane
// ─────────────────────────────────────────────────────────────────────────────

class _EditorPane extends ConsumerWidget {
  final String editorContent;
  final ValueChanged<String> onContentChanged;

  const _EditorPane({
    required this.editorContent,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectId = ref.watch(conventionProjectIdProvider);

    if (selectedProjectId == null) {
      return Container(
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: const Center(
          child: Text(
            'Select a project to view conventions',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final docAsync = ref.watch(conventionDocumentProvider);
    final editMode = ref.watch(conventionEditModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: docAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CodeOpsColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No conventions document found',
                  style: TextStyle(
                      color: CodeOpsColors.textTertiary, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                'Create one from a template below',
                style: TextStyle(
                    color: CodeOpsColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ),
        data: (doc) {
          if (doc == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No conventions document found',
                      style: TextStyle(
                          color: CodeOpsColors.textTertiary, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(
                    'Create one from a template below',
                    style: TextStyle(
                        color: CodeOpsColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Document info bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.rule_outlined,
                        size: 16, color: CodeOpsColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'CONVENTIONS.md',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textPrimary,
                        ),
                      ),
                    ),
                    if (doc.lastUpdatedByName != null)
                      Flexible(
                        child: Text(
                          'Last updated by ${doc.lastUpdatedByName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (doc.isFlagged == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CodeOpsColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag,
                                size: 10, color: CodeOpsColors.error),
                            SizedBox(width: 3),
                            Text(
                              'Flagged',
                              style: TextStyle(
                                fontSize: 9,
                                color: CodeOpsColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: CodeOpsColors.border),
              // Editor
              Expanded(
                child: ScribeEditor(
                  key: ValueKey('${doc.id}-$editMode'),
                  content: editMode
                      ? (editorContent.isNotEmpty
                          ? editorContent
                          : doc.currentContent ?? '')
                      : doc.currentContent ?? '',
                  language: 'markdown',
                  readOnly: !editMode,
                  onChanged: editMode ? onContentChanged : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Version History Panel
// ─────────────────────────────────────────────────────────────────────────────

class _VersionHistoryPanel extends ConsumerWidget {
  const _VersionHistoryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(conventionDocumentProvider);

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.history,
                    size: 16, color: CodeOpsColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Version History',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(conventionHistoryVisibleProvider.notifier)
                      .state = false,
                  icon: const Icon(Icons.close, size: 16),
                  color: CodeOpsColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          // Version list
          Expanded(
            child: docAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CodeOpsColors.primary,
                ),
              ),
              error: (_, __) => const Center(
                child: Text('Error loading versions',
                    style: TextStyle(
                        color: CodeOpsColors.error, fontSize: 12)),
              ),
              data: (doc) {
                if (doc == null || doc.id == null) {
                  return const Center(
                    child: Text('No document selected',
                        style: TextStyle(
                            color: CodeOpsColors.textTertiary,
                            fontSize: 12)),
                  );
                }

                final versions = doc.versions ?? [];
                if (versions.isEmpty) {
                  return const Center(
                    child: Text('No versions yet',
                        style: TextStyle(
                            color: CodeOpsColors.textTertiary,
                            fontSize: 12)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: versions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CodeOpsColors.border),
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return _VersionTile(version: version);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  final ProjectDocumentVersion version;

  const _VersionTile({required this.version});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'v${version.versionNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Author type badge
              if (version.authorType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: version.authorType == AuthorType.ai
                        ? CodeOpsColors.primary.withValues(alpha: 0.15)
                        : CodeOpsColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    version.authorType!.displayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: version.authorType == AuthorType.ai
                          ? CodeOpsColors.primary
                          : CodeOpsColors.success,
                    ),
                  ),
                ),
              const Spacer(),
              if (version.createdAt != null)
                Text(
                  DateFormat.yMMMd().format(version.createdAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
            ],
          ),
          if (version.changeDescription != null) ...[
            const SizedBox(height: 4),
            Text(
              version.changeDescription!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (version.authorName != null) ...[
            const SizedBox(height: 2),
            Text(
              version.authorName!,
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
          if (version.commitHash != null) ...[
            const SizedBox(height: 2),
            Text(
              version.commitHash!.length > 8
                  ? version.commitHash!.substring(0, 8)
                  : version.commitHash!,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Propagation Status Section
// ─────────────────────────────────────────────────────────────────────────────

class _PropagationSection extends ConsumerWidget {
  const _PropagationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propagationAsync = ref.watch(conventionPropagationProvider);

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
          Row(
            children: [
              const Icon(Icons.sync_outlined,
                  size: 18, color: CodeOpsColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Propagation Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(conventionPropagationProvider),
                icon: const Icon(Icons.refresh, size: 14),
                label:
                    const Text('Refresh', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          propagationAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            error: (_, __) => const Text('Failed to load propagation status',
                style: TextStyle(color: CodeOpsColors.error, fontSize: 12)),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No projects found',
                      style: TextStyle(
                          color: CodeOpsColors.textTertiary, fontSize: 12)),
                );
              }

              return Column(
                children: [
                  // Header row
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('Project',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CodeOpsColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Status',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CodeOpsColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Last Updated',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: CodeOpsColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: CodeOpsColors.border),
                  // Rows
                  for (final entry in entries)
                    _PropagationRow(entry: entry),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PropagationRow extends StatelessWidget {
  final ConventionPropagationEntry entry;

  const _PropagationRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              entry.project.name,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _PropagationBadge(status: entry.status),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.document?.updatedAt != null
                  ? DateFormat.yMMMd().format(entry.document!.updatedAt!)
                  : '—',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropagationBadge extends StatelessWidget {
  final PropagationStatus status;

  const _PropagationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      PropagationStatus.current => (
          CodeOpsColors.success,
          CodeOpsColors.success.withValues(alpha: 0.15),
        ),
      PropagationStatus.behind => (
          CodeOpsColors.warning,
          CodeOpsColors.warning.withValues(alpha: 0.15),
        ),
      PropagationStatus.custom => (
          CodeOpsColors.primary,
          CodeOpsColors.primary.withValues(alpha: 0.15),
        ),
      PropagationStatus.missing => (
          CodeOpsColors.error,
          CodeOpsColors.error.withValues(alpha: 0.15),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.displayName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convention Templates Section
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateSection extends ConsumerWidget {
  const _TemplateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectId = ref.watch(conventionProjectIdProvider);

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
          const Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: CodeOpsColors.primary),
              SizedBox(width: 8),
              Text(
                'Convention Templates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in conventionTemplates.entries)
                _TemplateCard(
                  name: entry.key,
                  content: entry.value,
                  enabled: selectedProjectId != null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final String name;
  final String content;
  final bool enabled;

  const _TemplateCard({
    required this.name,
    required this.content,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: enabled
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: CodeOpsColors.surface,
                    title: Text('Apply "$name" Template?',
                        style: const TextStyle(
                            color: CodeOpsColors.textPrimary, fontSize: 16)),
                    content: const Text(
                      'This will create a new conventions document for the selected project using this template.',
                      style: TextStyle(
                          color: CodeOpsColors.textSecondary, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final projectId =
                      ref.read(conventionProjectIdProvider);
                  if (projectId == null) return;
                  final api = ref.read(mcpApiProvider);
                  await api.createDocument(
                    projectId: projectId,
                    request: {
                      'documentType': 'CONVENTIONS_MD',
                      'initialContent': content,
                    },
                  );
                  ref.invalidate(conventionDocumentProvider);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? CodeOpsColors.border
                  : CodeOpsColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content.split('\n').take(3).join('\n'),
                style: TextStyle(
                  fontSize: 10,
                  color: enabled
                      ? CodeOpsColors.textSecondary
                      : CodeOpsColors.textTertiary,
                  fontFamily: 'monospace',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
