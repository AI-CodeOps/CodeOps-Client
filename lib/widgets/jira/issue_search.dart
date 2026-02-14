/// JQL search input with preset filter buttons.
///
/// Provides a text field for raw JQL input and a row of preset
/// filter buttons that auto-fill common JQL queries scoped to
/// a specific Jira project key. Search executes on Enter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/jira_providers.dart';
import '../../theme/colors.dart';

/// JQL search widget with preset filter buttons.
///
/// The [projectKey] scopes all preset queries to a specific Jira project.
/// Typing JQL and pressing Enter updates [jiraSearchQueryProvider] and
/// resets [jiraSearchStartAtProvider] to zero. Preset buttons populate
/// the text field with common JQL patterns.
class IssueSearch extends ConsumerStatefulWidget {
  /// The Jira project key used to scope preset JQL queries.
  ///
  /// When `null`, presets will not be project-scoped.
  final String? projectKey;

  /// Creates an [IssueSearch].
  const IssueSearch({super.key, this.projectKey});

  @override
  ConsumerState<IssueSearch> createState() => _IssueSearchState();
}

class _IssueSearchState extends ConsumerState<IssueSearch> {
  final _controller = TextEditingController();
  String? _activePreset;

  /// Preset filter definitions mapping label to JQL template.
  Map<String, String> get _presets {
    final pk = widget.projectKey;
    final prefix = pk != null ? 'project = $pk AND ' : '';
    return {
      'My Open Issues':
          '${prefix}assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC',
      'Unassigned Bugs':
          '${prefix}issuetype = Bug AND assignee is EMPTY ORDER BY priority DESC',
      'High Priority':
          '${prefix}priority in (Highest, High) AND statusCategory != Done ORDER BY priority DESC',
      'Sprint Backlog':
          '${prefix.isNotEmpty ? prefix : ''}sprint in openSprints() ORDER BY rank ASC',
      'Recently Updated':
          '${pk != null ? 'project = $pk ' : ''}ORDER BY updated DESC',
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Executes the search by updating the Riverpod providers.
  void _executeSearch(String jql) {
    final trimmed = jql.trim();
    ref.read(jiraSearchStartAtProvider.notifier).state = 0;
    ref.read(jiraSearchQueryProvider.notifier).state = trimmed;
  }

  /// Applies a preset JQL query.
  void _applyPreset(String label, String jql) {
    _controller.text = jql;
    setState(() => _activePreset = label);
    _executeSearch(jql);
  }

  /// Clears the search field and resets the query provider.
  void _clearSearch() {
    _controller.clear();
    setState(() => _activePreset = null);
    ref.read(jiraSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = ref.watch(jiraSearchQueryProvider);
    final searchResults = ref.watch(jiraSearchResultsProvider);
    final resultCount = searchResults.valueOrNull?.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _controller,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'Enter JQL query...',
            prefixIcon:
                const Icon(Icons.search, color: CodeOpsColors.textTertiary),
            suffixIcon: _controller.text.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resultCount != null && currentQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '$resultCount results',
                            style: const TextStyle(
                              color: CodeOpsColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: CodeOpsColors.textTertiary,
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      ),
                    ],
                  )
                : null,
            filled: true,
            fillColor: CodeOpsColors.surfaceVariant,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: CodeOpsColors.primary),
            ),
          ),
          onSubmitted: (value) {
            setState(() => _activePreset = null);
            _executeSearch(value);
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        // Preset filter buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.entries.map((entry) {
            final isActive = _activePreset == entry.key;
            return _PresetButton(
              label: entry.key,
              isActive: isActive,
              onPressed: () => _applyPreset(entry.key, entry.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// A compact filter preset button.
///
/// Renders as a styled chip-like button that highlights when [isActive].
class _PresetButton extends StatelessWidget {
  /// The button label.
  final String label;

  /// Whether this preset is currently active.
  final bool isActive;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a [_PresetButton].
  const _PresetButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? CodeOpsColors.primary.withValues(alpha: 0.15)
          : CodeOpsColors.surfaceVariant,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? CodeOpsColors.primary : CodeOpsColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
