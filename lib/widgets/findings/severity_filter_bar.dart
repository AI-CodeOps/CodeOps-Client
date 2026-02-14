/// Severity filter bar for findings explorer.
///
/// Toggle chips with counts, dropdowns for status/agent, search input,
/// sort control, and clear button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/finding_providers.dart';
import '../../theme/colors.dart';

/// Filter bar for the findings explorer.
class SeverityFilterBar extends ConsumerWidget {
  /// Severity counts for badge display.
  final Map<Severity, int> severityCounts;

  /// Called when search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Creates a [SeverityFilterBar].
  const SeverityFilterBar({
    super.key,
    this.severityCounts = const {},
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(findingFiltersProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          // Severity toggle chips
          Row(
            children: [
              ...Severity.values.map((severity) {
                final count = severityCounts[severity] ?? 0;
                final selected = filters.severity == severity;
                final color = CodeOpsColors.severityColors[severity]!;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      ref.read(findingFiltersProvider.notifier).state =
                          selected
                              ? filters.copyWith(clearSeverity: true)
                              : filters.copyWith(severity: severity);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : CodeOpsColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? color.withValues(alpha: 0.4)
                              : CodeOpsColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${severity.displayName} ($count)',
                            style: TextStyle(
                              color: selected
                                  ? color
                                  : CodeOpsColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Clear button
              if (filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    ref.read(findingFiltersProvider.notifier).state =
                        const FindingFilters();
                    onSearchChanged?.call('');
                  },
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: CodeOpsColors.textTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Second row: status dropdown, agent dropdown, search, sort
          Row(
            children: [
              // Status dropdown
              _FilterDropdown<FindingStatus>(
                hint: 'Status',
                value: filters.status,
                items: FindingStatus.values,
                labelFn: (s) => s.displayName,
                onChanged: (status) {
                  ref.read(findingFiltersProvider.notifier).state = status != null
                      ? filters.copyWith(status: status)
                      : filters.copyWith(clearStatus: true);
                },
              ),
              const SizedBox(width: 8),

              // Agent dropdown
              _FilterDropdown<AgentType>(
                hint: 'Agent',
                value: filters.agentType,
                items: AgentType.values,
                labelFn: (a) => a.displayName,
                onChanged: (agent) {
                  ref.read(findingFiltersProvider.notifier).state = agent != null
                      ? filters.copyWith(agentType: agent)
                      : filters.copyWith(clearAgentType: true);
                },
              ),
              const SizedBox(width: 8),

              // Search field
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (value) {
                      ref.read(findingFiltersProvider.notifier).state =
                          filters.copyWith(searchQuery: value);
                      onSearchChanged?.call(value);
                    },
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search findings...',
                      hintStyle: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: CodeOpsColors.textTertiary),
                      filled: true,
                      fillColor: CodeOpsColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: CodeOpsColors.primary,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort toggle
              IconButton(
                icon: Icon(
                  filters.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: CodeOpsColors.textSecondary,
                ),
                onPressed: () {
                  ref.read(findingFiltersProvider.notifier).state =
                      filters.copyWith(
                          sortAscending: !filters.sortAscending);
                },
                tooltip: filters.sortAscending
                    ? 'Sort ascending'
                    : 'Sort descending',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelFn;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelFn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down,
              size: 16, color: CodeOpsColors.textTertiary),
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 12,
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                'All',
                style: TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelFn(item)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
