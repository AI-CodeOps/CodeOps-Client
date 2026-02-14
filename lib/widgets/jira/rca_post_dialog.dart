/// Dialog for previewing and posting a Root Cause Analysis to Jira as a comment.
///
/// Displays the RCA markdown preview, allows editing the target issue key,
/// optionally transitions the issue status, and adds labels before posting.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/jira_models.dart';
import '../../providers/jira_providers.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';

/// A dialog that previews an RCA report and posts it as a Jira comment.
///
/// The dialog allows the user to:
/// - Preview the rendered RCA markdown
/// - Edit the target issue key
/// - Optionally transition the issue to a different status
/// - Optionally add labels to the issue
/// - Post the comment and apply changes
class RcaPostDialog extends ConsumerStatefulWidget {
  /// The RCA content in Markdown format.
  final String rcaMarkdown;

  /// The initial Jira issue key to post to.
  final String initialIssueKey;

  /// Creates an [RcaPostDialog].
  const RcaPostDialog({
    super.key,
    required this.rcaMarkdown,
    required this.initialIssueKey,
  });

  @override
  ConsumerState<RcaPostDialog> createState() => _RcaPostDialogState();
}

class _RcaPostDialogState extends ConsumerState<RcaPostDialog> {
  late final TextEditingController _issueKeyController;
  final _labelController = TextEditingController();

  bool _updateStatus = false;
  bool _addLabels = false;
  bool _posting = false;
  String? _error;

  List<JiraTransition> _transitions = [];
  JiraTransition? _selectedTransition;
  final List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _issueKeyController = TextEditingController(text: widget.initialIssueKey);
  }

  @override
  void dispose() {
    _issueKeyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  /// Loads available transitions for the current issue key.
  Future<void> _loadTransitions() async {
    final issueKey = _issueKeyController.text.trim();
    if (issueKey.isEmpty) return;

    try {
      final transitions =
          await ref.read(jiraTransitionsProvider(issueKey).future);
      if (mounted) {
        setState(() {
          _transitions = transitions;
          _selectedTransition =
              transitions.isNotEmpty ? transitions.first : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _transitions = [];
          _selectedTransition = null;
        });
      }
    }
  }

  /// Adds a label chip from the text field.
  void _addLabel() {
    final label = _labelController.text.trim();
    if (label.isEmpty || _labels.contains(label)) return;
    setState(() {
      _labels.add(label);
      _labelController.clear();
    });
  }

  /// Removes a label chip at the given [index].
  void _removeLabel(int index) {
    setState(() => _labels.removeAt(index));
  }

  /// Posts the RCA as a comment and optionally transitions/labels the issue.
  Future<void> _post() async {
    final issueKey = _issueKeyController.text.trim().toUpperCase();
    if (issueKey.isEmpty) {
      setState(() => _error = 'Issue key is required.');
      return;
    }

    final service = await ref.read(jiraServiceProvider.future);
    if (service == null) {
      setState(() => _error = 'Jira is not configured.');
      return;
    }

    setState(() {
      _posting = true;
      _error = null;
    });

    try {
      // Post the RCA as a Jira comment.
      await service.postComment(issueKey, widget.rcaMarkdown);

      // Optionally transition the issue.
      if (_updateStatus && _selectedTransition != null) {
        await service.transitionIssue(issueKey, _selectedTransition!.id);
      }

      // Optionally add labels.
      if (_addLabels && _labels.isNotEmpty) {
        await service.updateIssue(
          issueKey,
          UpdateJiraIssueRequest(labels: _labels),
        );
      }

      if (mounted) {
        showToast(
          context,
          message: 'RCA posted to $issueKey successfully.',
          type: ToastType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _posting = false;
          _error = 'Failed to post: ${_friendlyError(e)}';
        });
      }
    }
  }

  /// Extracts a user-friendly error message.
  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.length > 100) return '${msg.substring(0, 100)}...';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Row(
        children: [
          Icon(Icons.rate_review_outlined, color: CodeOpsColors.primary, size: 22),
          SizedBox(width: 10),
          Text(
            'Post RCA to Jira',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target issue key.
            _buildIssueKeyField(),
            const SizedBox(height: 12),
            // RCA Preview.
            const Text(
              'Comment Preview',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildPreviewPane()),
            const SizedBox(height: 12),
            // Options.
            _buildStatusOption(),
            const SizedBox(height: 8),
            _buildLabelOption(),
            // Error.
            if (_error != null) ...[
              const SizedBox(height: 10),
              _buildError(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _posting ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _posting ? null : _post,
          icon: _posting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send, size: 16),
          label: Text(_posting ? 'Posting...' : 'Post to Jira'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the target issue key input field.
  Widget _buildIssueKeyField() {
    return Row(
      children: [
        const Text(
          'Target Issue:',
          style: TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _issueKeyController,
            enabled: !_posting,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: CodeOpsColors.surfaceVariant,
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
            onChanged: (_) {
              if (_updateStatus) _loadTransitions();
            },
          ),
        ),
      ],
    );
  }

  /// Builds the scrollable RCA markdown preview pane.
  Widget _buildPreviewPane() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border, width: 1),
      ),
      child: Markdown(
        data: widget.rcaMarkdown,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 13,
            height: 1.5,
          ),
          h1: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          h2: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          h3: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          code: TextStyle(
            color: CodeOpsColors.secondary,
            backgroundColor: CodeOpsColors.background.withValues(alpha: 0.5),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          codeblockDecoration: BoxDecoration(
            color: CodeOpsColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          listBullet: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Builds the "Also update issue status" checkbox with transition dropdown.
  Widget _buildStatusOption() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _updateStatus,
            onChanged: _posting
                ? null
                : (v) {
                    setState(() => _updateStatus = v ?? false);
                    if (_updateStatus) _loadTransitions();
                  },
            activeColor: CodeOpsColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Also update issue status',
          style: TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (_updateStatus) ...[
          const SizedBox(width: 12),
          _transitions.isEmpty
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CodeOpsColors.primary,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<JiraTransition>(
                      value: _selectedTransition,
                      dropdownColor: CodeOpsColors.surfaceVariant,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                      ),
                      items: _transitions.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text('${t.name} (${t.to.name})'),
                        );
                      }).toList(),
                      onChanged: _posting
                          ? null
                          : (v) => setState(() => _selectedTransition = v),
                    ),
                  ),
                ),
        ],
      ],
    );
  }

  /// Builds the "Add labels" checkbox with label chip input.
  Widget _buildLabelOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _addLabels,
                onChanged: _posting
                    ? null
                    : (v) => setState(() => _addLabels = v ?? false),
                activeColor: CodeOpsColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Add labels',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (_addLabels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ..._labels.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(
                          entry.value,
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: CodeOpsColors.surfaceVariant,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        deleteIconColor: CodeOpsColors.textTertiary,
                        onDeleted: () => _removeLabel(entry.key),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: const BorderSide(
                          color: CodeOpsColors.border,
                          width: 1,
                        ),
                      );
                    }),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _labelController,
                        enabled: !_posting,
                        style: const TextStyle(
                          color: CodeOpsColors.textPrimary,
                          fontSize: 12,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add label...',
                          hintStyle: TextStyle(
                            color: CodeOpsColors.textTertiary,
                            fontSize: 11,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addLabel(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds the error text.
  Widget _buildError() {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: CodeOpsColors.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
