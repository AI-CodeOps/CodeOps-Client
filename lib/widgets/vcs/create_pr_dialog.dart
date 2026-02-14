/// Dialog for creating a new pull request.
///
/// Provides head/base branch dropdowns, title, description,
/// and draft checkbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// Dialog to create a new GitHub pull request.
class CreatePRDialog extends ConsumerStatefulWidget {
  /// Full name (owner/repo) of the repository.
  final String repoFullName;

  /// Creates a [CreatePRDialog].
  const CreatePRDialog({super.key, required this.repoFullName});

  @override
  ConsumerState<CreatePRDialog> createState() => _CreatePRDialogState();
}

class _CreatePRDialogState extends ConsumerState<CreatePRDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _headBranch;
  String? _baseBranch;
  bool _isDraft = false;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    if (_headBranch == null || _baseBranch == null) {
      setState(() => _error = 'Select both head and base branches');
      return;
    }
    if (_headBranch == _baseBranch) {
      setState(() => _error = 'Head and base branches must differ');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final provider = ref.read(vcsProviderProvider);
      await provider.createPullRequest(
        widget.repoFullName,
        CreatePRRequest(
          title: title,
          head: _headBranch!,
          base: _baseBranch!,
          body: _bodyController.text.trim().isNotEmpty
              ? _bodyController.text.trim()
              : null,
          draft: _isDraft,
        ),
      );

      ref.invalidate(repoPullRequestsProvider(widget.repoFullName));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create PR: $e';
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync =
        ref.watch(repoBranchesProvider(widget.repoFullName));

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Pull Request'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch selectors.
            branchesAsync.when(
              loading: () => const LinearProgressIndicator(
                color: CodeOpsColors.primary,
              ),
              error: (_, __) => const Text(
                'Could not load branches',
                style: TextStyle(color: CodeOpsColors.error, fontSize: 13),
              ),
              data: (branches) {
                final names = branches.map((b) => b.name).toList();
                return Row(
                  children: [
                    Expanded(
                      child: _branchDropdown(
                        label: 'Head',
                        value: _headBranch,
                        items: names,
                        onChanged: (v) =>
                            setState(() => _headBranch = v),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16,
                          color: CodeOpsColors.textTertiary),
                    ),
                    Expanded(
                      child: _branchDropdown(
                        label: 'Base',
                        value: _baseBranch,
                        items: names,
                        onChanged: (v) =>
                            setState(() => _baseBranch = v),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Title.
            TextField(
              controller: _titleController,
              enabled: !_creating,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Description.
            TextField(
              controller: _bodyController,
              enabled: !_creating,
              maxLines: 4,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Draft checkbox.
            Row(
              children: [
                Checkbox(
                  value: _isDraft,
                  onChanged: _creating
                      ? null
                      : (v) => setState(() => _isDraft = v ?? false),
                ),
                const Text(
                  'Create as draft',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: CodeOpsColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _branchDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      dropdownColor: CodeOpsColors.surfaceVariant,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((name) => DropdownMenuItem(
                value: name,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ))
          .toList(),
      onChanged: _creating ? null : onChanged,
    );
  }
}
