/// Finding filter step for remediation wizard mode.
///
/// Filter bar (severity, agent type, status, file search), selectable
/// findings table, and quick actions. Validation: at least one
/// finding must be selected.
library;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/finding.dart';
import '../../theme/colors.dart';
import '../progress/agent_card.dart';
import '../shared/search_bar.dart';

/// Finding filter step for the remediation wizard flow.
class FindingFilterStep extends StatefulWidget {
  /// All available findings.
  final List<Finding> findings;

  /// Set of selected finding IDs.
  final Set<String> selectedIds;

  /// Called when selection changes.
  final ValueChanged<Set<String>> onSelectionChanged;

  /// Creates a [FindingFilterStep].
  const FindingFilterStep({
    super.key,
    required this.findings,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<FindingFilterStep> createState() => _FindingFilterStepState();
}

class _FindingFilterStepState extends State<FindingFilterStep> {
  Severity? _severityFilter;
  AgentType? _agentTypeFilter;
  String _searchQuery = '';

  List<Finding> get _filtered {
    var filtered = widget.findings;
    if (_severityFilter != null) {
      filtered = filtered.where((f) => f.severity == _severityFilter).toList();
    }
    if (_agentTypeFilter != null) {
      filtered =
          filtered.where((f) => f.agentType == _agentTypeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((f) {
        return f.title.toLowerCase().contains(q) ||
            (f.filePath?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Findings',
          style: TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.selectedIds.length} of ${widget.findings.length} findings selected.',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Filter bar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Severity filter
            _FilterDropdown<Severity>(
              label: 'Severity',
              value: _severityFilter,
              items: Severity.values,
              itemLabel: (s) => s.displayName,
              onChanged: (v) => setState(() => _severityFilter = v),
            ),

            // Agent type filter
            _FilterDropdown<AgentType>(
              label: 'Agent',
              value: _agentTypeFilter,
              items: AgentType.values,
              itemLabel: (a) => a.displayName,
              onChanged: (v) => setState(() => _agentTypeFilter = v),
            ),

            // Search
            SizedBox(
              width: 200,
              child: CodeOpsSearchBar(
                hint: 'Search findings...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick actions
        Row(
          children: [
            TextButton(
              onPressed: () {
                widget.onSelectionChanged(
                  filtered.map((f) => f.id).toSet(),
                );
              },
              child: const Text('Select visible'),
            ),
            TextButton(
              onPressed: () => widget.onSelectionChanged({}),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Findings list
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No findings match filters',
                    style: TextStyle(color: CodeOpsColors.textTertiary),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: CodeOpsColors.divider),
                  itemBuilder: (context, index) {
                    final finding = filtered[index];
                    final isSelected =
                        widget.selectedIds.contains(finding.id);
                    return _FindingRow(
                      finding: finding,
                      isSelected: isSelected,
                      onToggle: () {
                        final updated = Set<String>.from(widget.selectedIds);
                        if (isSelected) {
                          updated.remove(finding.id);
                        } else {
                          updated.add(finding.id);
                        }
                        widget.onSelectionChanged(updated);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T?>(
      value: value,
      hint: Text(label,
          style: const TextStyle(
              color: CodeOpsColors.textSecondary, fontSize: 12)),
      dropdownColor: CodeOpsColors.surface,
      style: const TextStyle(
          color: CodeOpsColors.textPrimary, fontSize: 12),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text('All $label'),
        ),
        ...items.map((item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(itemLabel(item)),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

class _FindingRow extends StatelessWidget {
  final Finding finding;
  final bool isSelected;
  final VoidCallback onToggle;

  const _FindingRow({
    required this.finding,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor =
        CodeOpsColors.severityColors[finding.severity] ??
            CodeOpsColors.warning;
    final meta = AgentTypeMetadata.all[finding.agentType];

    return Material(
      color: isSelected
          ? CodeOpsColors.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: CodeOpsColors.primary,
                side: const BorderSide(
                    color: CodeOpsColors.textTertiary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  finding.severity.displayName,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (meta != null) ...[
                Icon(meta.icon,
                    size: 14, color: CodeOpsColors.textTertiary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finding.title,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (finding.filePath != null)
                      Text(
                        finding.filePath!,
                        style: const TextStyle(
                          color: CodeOpsColors.textTertiary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
