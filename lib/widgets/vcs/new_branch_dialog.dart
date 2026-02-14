/// Dialog for creating a new git branch.
///
/// Validates the branch name and calls [GitService.createBranch].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// Dialog to create a new branch from the current branch.
class NewBranchDialog extends ConsumerStatefulWidget {
  /// Local path of the repository.
  final String repoDir;

  /// Current branch name shown as "Create from".
  final String currentBranch;

  /// Creates a [NewBranchDialog].
  const NewBranchDialog({
    super.key,
    required this.repoDir,
    required this.currentBranch,
  });

  @override
  ConsumerState<NewBranchDialog> createState() => _NewBranchDialogState();
}

class _NewBranchDialogState extends ConsumerState<NewBranchDialog> {
  final _nameController = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Branch name is required');
      return;
    }
    if (name.contains(' ') || name.contains('..') || name.contains('~')) {
      setState(() => _error = 'Invalid branch name');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final gitService = ref.read(gitServiceProvider);
      await gitService.createBranch(
        widget.repoDir,
        name,
        startPoint: widget.currentBranch,
      );
      if (mounted) Navigator.of(context).pop(name);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create branch: $e';
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('New Branch'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create from: ${widget.currentBranch}',
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_creating,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Branch name',
                hintText: 'feature/my-feature',
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CodeOpsColors.primary),
                ),
              ),
              onSubmitted: (_) => _create(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
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
              : const Text('Create Branch'),
        ),
      ],
    );
  }
}
