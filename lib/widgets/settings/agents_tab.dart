/// Agents tab with master-detail layout for per-agent configuration.
///
/// Left panel shows a searchable, grouped agent list. Right panel
/// shows the detail editor for the selected agent.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'agent_detail_panel.dart';
import 'agent_list_panel.dart';

/// Master-detail container for agent definitions.
class AgentsTab extends StatelessWidget {
  /// Creates an [AgentsTab].
  const AgentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: agent list.
        const Expanded(
          flex: 2,
          child: AgentListPanel(),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: CodeOpsColors.border,
        ),
        // Right panel: agent detail editor.
        const Expanded(
          flex: 3,
          child: AgentDetailPanel(),
        ),
      ],
    );
  }
}
