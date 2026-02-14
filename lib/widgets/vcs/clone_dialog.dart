/// Dialog for cloning a GitHub repository.
///
/// Shows branch selector, target directory picker, and streaming progress.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// Clone dialog for a specific repository.
class CloneDialog extends ConsumerStatefulWidget {
  /// The repository to clone.
  final VcsRepository repo;

  /// Creates a [CloneDialog].
  const CloneDialog({super.key, required this.repo});

  @override
  ConsumerState<CloneDialog> createState() => _CloneDialogState();
}

class _CloneDialogState extends ConsumerState<CloneDialog> {
  late final TextEditingController _dirController;
  String? _selectedBranch;
  bool _cloning = false;
  String _progressText = '';
  double _progressPercent = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final repoManager = ref.read(repoManagerProvider);
    _dirController = TextEditingController(
      text: repoManager.getRepoPath(widget.repo.fullName),
    );
    _selectedBranch = widget.repo.defaultBranch;
  }

  @override
  void dispose() {
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _startClone() async {
    final targetDir = _dirController.text.trim();
    if (targetDir.isEmpty) {
      setState(() => _error = 'Please specify a target directory');
      return;
    }

    setState(() {
      _cloning = true;
      _error = null;
      _progressText = 'Initializing clone...';
      _progressPercent = 0;
    });

    try {
      // Ensure parent directory exists.
      final parent = Directory(targetDir).parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }

      final gitService = ref.read(gitServiceProvider);
      final cloneUrl = widget.repo.cloneUrl ?? widget.repo.htmlUrl ?? '';

      await gitService.clone(
        cloneUrl,
        targetDir,
        branch: _selectedBranch,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progressText = '${progress.phase}: ${progress.percent}%';
              _progressPercent = progress.percent / 100;
            });
          }
        },
      );

      // Register in DB.
      final repoManager = ref.read(repoManagerProvider);
      await repoManager.registerRepo(
        repoFullName: widget.repo.fullName,
        localPath: targetDir,
      );

      // Refresh cloned repos list.
      ref.invalidate(clonedReposProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Clone failed: $e';
          _cloning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync =
        ref.watch(repoBranchesProvider(widget.repo.fullName));

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text('Clone ${widget.repo.name}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch selector.
            const Text(
              'Branch',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            branchesAsync.when(
              loading: () => const LinearProgressIndicator(
                color: CodeOpsColors.primary,
              ),
              error: (_, __) => Text(
                'Using default: ${widget.repo.defaultBranch}',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
              data: (branches) => DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                dropdownColor: CodeOpsColors.surfaceVariant,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: CodeOpsColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                items: branches
                    .map((b) => DropdownMenuItem(
                          value: b.name,
                          child: Text(
                            b.name,
                            style: const TextStyle(
                              color: CodeOpsColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: _cloning
                    ? null
                    : (v) => setState(() => _selectedBranch = v),
              ),
            ),
            const SizedBox(height: 16),
            // Target directory.
            const Text(
              'Target Directory',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _dirController,
              enabled: !_cloning,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_cloning) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progressPercent,
                color: CodeOpsColors.primary,
                backgroundColor: CodeOpsColors.surfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                _progressText,
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
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
          onPressed: _cloning ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _cloning ? null : _startClone,
          child: const Text('Clone'),
        ),
      ],
    );
  }
}
