/// Quick-pick widget for selecting a Jira issue by key or search.
///
/// Provides a text field with debounced autocomplete suggestions fetched
/// via JQL search, a fetch button for explicit key lookup, and clear/error states.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/jira_models.dart';
import '../../providers/jira_providers.dart';
import '../../services/jira/jira_mapper.dart';
import '../../theme/colors.dart';

/// A widget for selecting a Jira issue by typing its key or searching.
///
/// As the user types, autocomplete suggestions are fetched via a debounced
/// JQL search. The user can also type a full issue key and press the fetch
/// button to load a specific issue directly.
///
/// Calls [onIssueSelected] with the full [JiraIssue] when an issue is chosen.
class IssuePicker extends ConsumerStatefulWidget {
  /// Called when the user selects or fetches a Jira issue.
  final ValueChanged<JiraIssue> onIssueSelected;

  /// Optional initial issue key to pre-fill the text field.
  final String? initialIssueKey;

  /// Creates an [IssuePicker].
  const IssuePicker({
    super.key,
    required this.onIssueSelected,
    this.initialIssueKey,
  });

  @override
  ConsumerState<IssuePicker> createState() => _IssuePickerState();
}

class _IssuePickerState extends ConsumerState<IssuePicker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<JiraIssue> _suggestions = [];
  bool _loading = false;
  bool _showSuggestions = false;
  String? _error;
  JiraIssue? _selectedIssue;

  @override
  void initState() {
    super.initState();
    if (widget.initialIssueKey != null) {
      _controller.text = widget.initialIssueKey!;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// Handles focus changes to show/hide the suggestion dropdown.
  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay to allow tap on suggestion to register.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  /// Debounces text input and triggers JQL search after 300ms.
  void _onTextChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _selectedIssue = null;
      _error = null;
    });

    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchIssues(value.trim());
    });
  }

  /// Searches Jira for issues matching the given [query].
  Future<void> _searchIssues(String query) async {
    final service = await ref.read(jiraServiceProvider.future);
    if (service == null) {
      setState(() => _error = 'Jira is not configured.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Search by key or text: if query looks like an issue key, search by key;
      // otherwise search summary.
      final isKeyPattern = RegExp(r'^[A-Z]+-\d*$', caseSensitive: false)
          .hasMatch(query);
      final jql = isKeyPattern
          ? 'key = "$query" OR key ~ "$query" ORDER BY updated DESC'
          : 'summary ~ "$query" ORDER BY updated DESC';

      final result = await service.searchIssues(
        jql: jql,
        maxResults: 8,
        fields: ['summary', 'status', 'issuetype', 'priority', 'assignee'],
      );
      if (mounted) {
        setState(() {
          _suggestions = result.issues;
          _showSuggestions = result.issues.isNotEmpty;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _loading = false;
          _error = 'Search failed: ${_extractErrorMessage(e)}';
        });
      }
    }
  }

  /// Fetches a specific issue by the exact key entered.
  Future<void> _fetchByKey() async {
    final key = _controller.text.trim().toUpperCase();
    if (key.isEmpty) {
      setState(() => _error = 'Enter an issue key.');
      return;
    }

    final service = await ref.read(jiraServiceProvider.future);
    if (service == null) {
      setState(() => _error = 'Jira is not configured.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _showSuggestions = false;
    });

    try {
      final issue = await service.getIssue(key);
      if (mounted) {
        setState(() {
          _selectedIssue = issue;
          _controller.text = issue.key;
          _loading = false;
        });
        widget.onIssueSelected(issue);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Issue "$key" not found.';
        });
      }
    }
  }

  /// Selects a suggestion from the dropdown.
  void _selectSuggestion(JiraIssue issue) {
    setState(() {
      _selectedIssue = issue;
      _controller.text = issue.key;
      _showSuggestions = false;
      _error = null;
    });
    widget.onIssueSelected(issue);
  }

  /// Clears the current selection and input.
  void _clear() {
    _debounce?.cancel();
    setState(() {
      _controller.clear();
      _selectedIssue = null;
      _suggestions = [];
      _showSuggestions = false;
      _error = null;
    });
  }

  /// Extracts a user-friendly error message from an exception.
  String _extractErrorMessage(Object error) {
    final message = error.toString();
    if (message.length > 80) return '${message.substring(0, 80)}...';
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputRow(),
        if (_showSuggestions && _suggestions.isNotEmpty) _buildSuggestionList(),
        if (_selectedIssue != null) _buildSelectedBanner(),
        if (_error != null) _buildErrorBanner(),
      ],
    );
  }

  /// Builds the text input row with fetch and clear buttons.
  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSubmitted: (_) => _fetchByKey(),
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'Enter issue key (e.g., PAY-456)',
              hintStyle: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: CodeOpsColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: CodeOpsColors.primary,
                  width: 1,
                ),
              ),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CodeOpsColors.primary,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: CodeOpsColors.textTertiary,
                            size: 18,
                          ),
                          onPressed: _clear,
                          splashRadius: 16,
                          tooltip: 'Clear',
                        )
                      : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _loading ? null : _fetchByKey,
          icon: const Icon(Icons.search, size: 20),
          color: CodeOpsColors.primary,
          tooltip: 'Fetch issue',
          splashRadius: 20,
          style: IconButton.styleFrom(
            backgroundColor: CodeOpsColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
      ],
    );
  }

  /// Builds the autocomplete suggestion dropdown.
  Widget _buildSuggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) =>
            const Divider(color: CodeOpsColors.border, height: 1),
        itemBuilder: (context, index) {
          final issue = _suggestions[index];
          final statusColor = JiraMapper.mapStatusColor(
            issue.fields.status.statusCategory,
          );

          return InkWell(
            onTap: () => _selectSuggestion(issue),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    issue.key,
                    style: const TextStyle(
                      color: CodeOpsColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.fields.summary,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      issue.fields.status.name,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the banner displayed when an issue is selected.
  Widget _buildSelectedBanner() {
    final issue = _selectedIssue!;
    final statusColor = JiraMapper.mapStatusColor(
      issue.fields.status.statusCategory,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: CodeOpsColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            issue.key,
            style: const TextStyle(
              color: CodeOpsColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.fields.summary,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              issue.fields.status.name,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error banner.
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: CodeOpsColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: CodeOpsColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
