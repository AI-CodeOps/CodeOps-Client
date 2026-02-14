/// Jira Browser page — browse and search Jira issues.
///
/// Route: `/bugs/jira`
/// Section: Maintain
///
/// Master-detail layout: left = issue list with search and filters,
/// right = detail panel for the selected issue.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/health_snapshot.dart';
import '../providers/jira_providers.dart';
import '../providers/project_providers.dart' hide jiraConnectionsProvider;
import '../theme/colors.dart';
import '../widgets/jira/issue_browser.dart';
import '../widgets/jira/issue_detail_panel.dart';
import '../widgets/jira/issue_search.dart';
import '../widgets/jira/jira_connection_dialog.dart';
import '../widgets/shared/empty_state.dart';

/// Jira Browser page for browsing and searching Jira issues.
///
/// Features:
/// - Connection selector in the header area
/// - JQL search with preset filters
/// - Master-detail layout with issue list and detail panel
/// - Keyboard navigation (up/down arrows, Enter to select)
class JiraBrowserPage extends ConsumerStatefulWidget {
  /// Creates a [JiraBrowserPage].
  const JiraBrowserPage({super.key});

  @override
  ConsumerState<JiraBrowserPage> createState() => _JiraBrowserPageState();
}

class _JiraBrowserPageState extends ConsumerState<JiraBrowserPage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = ref.watch(isJiraConfiguredProvider);
    final connectionsAsync = ref.watch(jiraConnectionsProvider);
    final activeConnection = ref.watch(activeJiraConnectionProvider);
    final selectedIssueKey = ref.watch(selectedJiraIssueKeyProvider);

    // Get current project's Jira project key for search presets.
    final selectedProject = ref.watch(selectedProjectProvider);
    final projectKey = selectedProject.valueOrNull?.jiraProjectKey;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event),
      child: Container(
        color: CodeOpsColors.background,
        child: connectionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CodeOpsColors.primary),
          ),
          error: (error, _) => Center(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load connections',
              subtitle: error.toString(),
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(jiraConnectionsProvider),
            ),
          ),
          data: (connections) {
            // Not configured — show setup prompt.
            if (!isConfigured && connections.isEmpty) {
              return _NotConfiguredState(
                onConfigure: () => _showConnectionDialog(),
              );
            }

            // Auto-select first connection if none active.
            if (activeConnection == null && connections.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(activeJiraConnectionProvider.notifier).state =
                    connections.first;
              });
              return const Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              );
            }

            return Column(
              children: [
                // Connection selector bar
                _ConnectionBar(
                  connections: connections,
                  activeConnection: activeConnection,
                  onConnectionChanged: (conn) {
                    ref.read(activeJiraConnectionProvider.notifier).state =
                        conn;
                    ref.read(selectedJiraIssueKeyProvider.notifier).state =
                        null;
                  },
                  onAddConnection: () => _showConnectionDialog(),
                ),
                const Divider(height: 1, color: CodeOpsColors.border),

                // Search bar
                IssueSearch(projectKey: projectKey),
                const Divider(height: 1, color: CodeOpsColors.border),

                // Master-detail layout
                Expanded(
                  child: Row(
                    children: [
                      // Left: issue list
                      Expanded(
                        flex: selectedIssueKey != null ? 5 : 10,
                        child: IssueBrowser(
                          onIssueSelected: (displayModel) {
                            ref
                                .read(
                                    selectedJiraIssueKeyProvider.notifier)
                                .state = displayModel.key;
                          },
                        ),
                      ),
                      // Right: detail panel (shown when issue selected)
                      if (selectedIssueKey != null) ...[
                        const VerticalDivider(
                          width: 1,
                          color: CodeOpsColors.border,
                        ),
                        Expanded(
                          flex: 5,
                          child: IssueDetailPanel(
                            issueKey: selectedIssueKey,
                            onClose: () {
                              ref
                                  .read(selectedJiraIssueKeyProvider
                                      .notifier)
                                  .state = null;
                            },
                            onInvestigate: (_) {
                              // Navigate to Bug Investigator with issue key.
                              context.go('/bugs');
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (_) => const JiraConnectionDialog(),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final searchResults = ref.read(jiraSearchResultsProvider).valueOrNull;
    if (searchResults == null || searchResults.issues.isEmpty) return;

    final currentKey = ref.read(selectedJiraIssueKeyProvider);
    final issues = searchResults.issues;
    final currentIndex =
        issues.indexWhere((i) => i.key == currentKey);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final nextIndex =
          currentIndex < issues.length - 1 ? currentIndex + 1 : 0;
      ref.read(selectedJiraIssueKeyProvider.notifier).state =
          issues[nextIndex].key;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final prevIndex =
          currentIndex > 0 ? currentIndex - 1 : issues.length - 1;
      ref.read(selectedJiraIssueKeyProvider.notifier).state =
          issues[prevIndex].key;
    }
  }
}

// ---------------------------------------------------------------------------
// Not configured state
// ---------------------------------------------------------------------------

class _NotConfiguredState extends StatelessWidget {
  final VoidCallback onConfigure;

  const _NotConfiguredState({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.link_off,
        title: 'No Jira Connection',
        subtitle: 'Configure a Jira Cloud connection to browse issues.',
        actionLabel: 'Configure Jira',
        onAction: onConfigure,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection selector bar
// ---------------------------------------------------------------------------

class _ConnectionBar extends StatelessWidget {
  final List<JiraConnection> connections;
  final JiraConnection? activeConnection;
  final ValueChanged<JiraConnection> onConnectionChanged;
  final VoidCallback onAddConnection;

  const _ConnectionBar({
    required this.connections,
    required this.activeConnection,
    required this.onConnectionChanged,
    required this.onAddConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_outlined,
            size: 16,
            color: CodeOpsColors.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Connection:',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activeConnection?.id,
              dropdownColor: CodeOpsColors.surface,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
              items: connections
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final conn = connections.firstWhere((c) => c.id == id);
                onConnectionChanged(conn);
              },
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Add connection',
            onPressed: onAddConnection,
          ),
        ],
      ),
    );
  }
}
