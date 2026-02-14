/// Agent selection step for the wizard.
///
/// Shows a grid of agent cards with icons, descriptions, and checkboxes.
/// Includes a quick-select bar (All/None/Recommended).
/// Validation: at least one agent must be selected.
library;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/colors.dart';
import '../progress/agent_card.dart';

/// Agent selection step for the wizard flow.
class AgentSelectorStep extends StatelessWidget {
  /// The set of currently selected agent types.
  final Set<AgentType> selectedAgents;

  /// Called when an agent is toggled.
  final ValueChanged<AgentType> onToggle;

  /// Called when "Select All" is pressed.
  final VoidCallback onSelectAll;

  /// Called when "Select None" is pressed.
  final VoidCallback onSelectNone;

  /// Called when "Recommended" is pressed.
  final VoidCallback? onSelectRecommended;

  /// Creates an [AgentSelectorStep].
  const AgentSelectorStep({
    super.key,
    required this.selectedAgents,
    required this.onToggle,
    required this.onSelectAll,
    required this.onSelectNone,
    this.onSelectRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Agents',
          style: TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose which AI agents to run. ${selectedAgents.length} of ${AgentType.values.length} selected.',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Quick-select bar
        Row(
          children: [
            _QuickSelectChip(
              label: 'All',
              isActive: selectedAgents.length == AgentType.values.length,
              onTap: onSelectAll,
            ),
            const SizedBox(width: 8),
            _QuickSelectChip(
              label: 'None',
              isActive: selectedAgents.isEmpty,
              onTap: onSelectNone,
            ),
            if (onSelectRecommended != null) ...[
              const SizedBox(width: 8),
              _QuickSelectChip(
                label: 'Recommended',
                isActive: false,
                onTap: onSelectRecommended!,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Agent grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 500 ? 2 : (constraints.maxWidth < 800 ? 3 : 4);
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: AgentType.values.length,
                itemBuilder: (context, index) {
                  final agent = AgentType.values[index];
                  final isSelected = selectedAgents.contains(agent);
                  return _AgentSelectCard(
                    agentType: agent,
                    isSelected: isSelected,
                    onTap: () => onToggle(agent),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : CodeOpsColors.textSecondary,
          fontSize: 12,
        ),
      ),
      onPressed: onTap,
      backgroundColor: isActive
          ? CodeOpsColors.primary
          : CodeOpsColors.surfaceVariant,
      side: BorderSide.none,
    );
  }
}

class _AgentSelectCard extends StatelessWidget {
  final AgentType agentType;
  final bool isSelected;
  final VoidCallback onTap;

  const _AgentSelectCard({
    required this.agentType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = AgentTypeMetadata.all[agentType]!;

    return Material(
      color: isSelected
          ? CodeOpsColors.primary.withValues(alpha: 0.08)
          : CodeOpsColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? CodeOpsColors.primary
                  : CodeOpsColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                meta.icon,
                size: 20,
                color: isSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      meta.displayName,
                      style: TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      meta.description,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: CodeOpsColors.primary,
                side: const BorderSide(color: CodeOpsColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
