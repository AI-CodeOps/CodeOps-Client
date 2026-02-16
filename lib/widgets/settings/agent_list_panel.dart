/// Left panel of the agents tab showing a searchable, grouped agent list.
///
/// Vera is pinned at the top, followed by built-in agents by sort order,
/// then custom agents below a divider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../providers/agent_config_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/search_bar.dart';
import 'new_agent_dialog.dart';

/// Searchable, grouped list of agent definitions.
class AgentListPanel extends ConsumerWidget {
  /// Creates an [AgentListPanel].
  const AgentListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentDefinitionsProvider);
    final searchQuery = ref.watch(agentSearchQueryProvider);
    final selectedId = ref.watch(selectedAgentIdProvider);

    return Column(
      children: [
        // Header.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Agents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Agent',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => _showNewAgentDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CodeOpsSearchBar(
                hint: 'Search agents...',
                onChanged: (value) =>
                    ref.read(agentSearchQueryProvider.notifier).state = value,
              ),
            ],
          ),
        ),

        // Agent list.
        Expanded(
          child: agentsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: CodeOpsColors.error)),
            ),
            data: (agents) {
              final filtered = _filterAgents(agents, searchQuery);
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No agents found.',
                      style: TextStyle(
                          color: CodeOpsColors.textTertiary, fontSize: 13)),
                );
              }

              // Group: Vera first, then built-in, then custom.
              final vera =
                  filtered.where((a) => a.isQaManager).toList();
              final builtIn = filtered
                  .where((a) => a.isBuiltIn && !a.isQaManager)
                  .toList();
              final custom =
                  filtered.where((a) => !a.isBuiltIn).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  ...vera.map((a) => _AgentTile(
                        agent: a,
                        isSelected: a.id == selectedId,
                      )),
                  ...builtIn.map((a) => _AgentTile(
                        agent: a,
                        isSelected: a.id == selectedId,
                      )),
                  if (custom.isNotEmpty) ...[
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Divider(height: 1),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text('Custom Agents',
                          style: TextStyle(
                              fontSize: 11,
                              color: CodeOpsColors.textTertiary,
                              fontWeight: FontWeight.w500)),
                    ),
                    ...custom.map((a) => _AgentTile(
                          agent: a,
                          isSelected: a.id == selectedId,
                        )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<AgentDefinition> _filterAgents(
      List<AgentDefinition> agents, String query) {
    if (query.isEmpty) return agents;
    final lower = query.toLowerCase();
    return agents
        .where((a) => a.name.toLowerCase().contains(lower))
        .toList();
  }

  void _showNewAgentDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => const NewAgentDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Agent list tile
// ---------------------------------------------------------------------------

class _AgentTile extends ConsumerStatefulWidget {
  final AgentDefinition agent;
  final bool isSelected;

  const _AgentTile({required this.agent, required this.isSelected});

  @override
  ConsumerState<_AgentTile> createState() => _AgentTileState();
}

class _AgentTileState extends ConsumerState<_AgentTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ListTile(
        dense: true,
        selected: widget.isSelected,
        selectedTileColor: CodeOpsColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        leading: SizedBox(
          width: 24,
          child: Checkbox(
            value: agent.isEnabled,
            onChanged: (v) async {
              final service = ref.read(agentConfigServiceProvider);
              await service.updateAgent(agent.id, isEnabled: v ?? true);
              ref.invalidate(agentDefinitionsProvider);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        title: Row(
          children: [
            if (agent.isBuiltIn)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 14, color: CodeOpsColors.warning),
              ),
            if (agent.isQaManager)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.shield, size: 14, color: CodeOpsColors.primary),
              ),
            Expanded(
              child: Text(
                agent.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: agent.isEnabled
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: (!agent.isBuiltIn && _hovering)
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: CodeOpsColors.error,
                onPressed: () => _deleteAgent(context, agent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              )
            : null,
        onTap: () =>
            ref.read(selectedAgentIdProvider.notifier).state = agent.id,
      ),
    );
  }

  Future<void> _deleteAgent(
      BuildContext context, AgentDefinition agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text('Delete "${agent.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: CodeOpsColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ref.read(agentConfigServiceProvider);
      await service.deleteAgent(agent.id);
      ref.invalidate(agentDefinitionsProvider);

      // Clear selection if this agent was selected.
      if (ref.read(selectedAgentIdProvider) == agent.id) {
        ref.read(selectedAgentIdProvider.notifier).state = null;
      }
    }
  }
}
