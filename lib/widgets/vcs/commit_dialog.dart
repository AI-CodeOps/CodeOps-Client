/// Dialog for staging and committing changes.
///
/// Shows file checkboxes, stage all/unstage all toggles, commit message
/// input with character count, and commit & push button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// Dialog for creating a git commit.
class CommitDialog extends ConsumerStatefulWidget {
  /// Local path of the repository.
  final String repoDir;

  /// List of file changes to display.
  final List<FileChange> changes;

  /// Creates a [CommitDialog].
  const CommitDialog({
    super.key,
    required this.repoDir,
    required this.changes,
  });

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  final _messageController = TextEditingController();
  late final Set<String> _selectedFiles;
  bool _committing = false;
  bool _alsoPublish = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedFiles = widget.changes.map((c) => c.path).toSet();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Commit message is required');
      return;
    }
    if (_selectedFiles.isEmpty) {
      setState(() => _error = 'Select at least one file');
      return;
    }

    setState(() {
      _committing = true;
      _error = null;
    });

    try {
      final gitService = ref.read(gitServiceProvider);
      await gitService.commit(
        widget.repoDir,
        message,
        files: _selectedFiles.toList(),
      );

      if (_alsoPublish) {
        await gitService.push(widget.repoDir);
      }

      ref.invalidate(selectedRepoStatusProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Commit failed: $e';
          _committing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedFiles.length == widget.changes.length;

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Commit Changes'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File list header.
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: _committing
                      ? null
                      : (_) {
                          setState(() {
                            if (allSelected) {
                              _selectedFiles.clear();
                            } else {
                              _selectedFiles.addAll(
                                widget.changes.map((c) => c.path),
                              );
                            }
                          });
                        },
                ),
                Text(
                  '${_selectedFiles.length}/${widget.changes.length} files',
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(color: CodeOpsColors.border, height: 1),
            // File list.
            Expanded(
              child: ListView.builder(
                itemCount: widget.changes.length,
                itemBuilder: (context, index) {
                  final change = widget.changes[index];
                  final checked = _selectedFiles.contains(change.path);
                  return CheckboxListTile(
                    dense: true,
                    value: checked,
                    onChanged: _committing
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _selectedFiles.add(change.path);
                              } else {
                                _selectedFiles.remove(change.path);
                              }
                            });
                          },
                    title: Text(
                      change.path,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      change.type.displayName,
                      style: TextStyle(
                        color: _changeColor(change.type),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Commit message.
            TextField(
              controller: _messageController,
              enabled: !_committing,
              maxLines: 3,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: 'Commit message',
                hintText: 'Describe your changes...',
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterText: '${_messageController.text.length}/72',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _alsoPublish,
                  onChanged: _committing
                      ? null
                      : (v) => setState(() => _alsoPublish = v ?? false),
                ),
                const Text(
                  'Push after commit',
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
          onPressed: _committing ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _committing ? null : _commit,
          child: _committing
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_alsoPublish ? 'Commit & Push' : 'Commit'),
        ),
      ],
    );
  }

  static Color _changeColor(FileChangeType type) => switch (type) {
        FileChangeType.added => CodeOpsColors.success,
        FileChangeType.modified => CodeOpsColors.warning,
        FileChangeType.deleted => CodeOpsColors.error,
        FileChangeType.renamed => CodeOpsColors.secondary,
        FileChangeType.copied => CodeOpsColors.secondary,
        FileChangeType.untracked => CodeOpsColors.textTertiary,
      };
}
