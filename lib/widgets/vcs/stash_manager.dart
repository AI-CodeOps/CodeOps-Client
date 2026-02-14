/// Stash manager widget.
///
/// Shows the stash list with pop/drop actions, a "Stash Changes" button,
/// and a confirmation dialog before dropping.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vcs_models.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/confirm_dialog.dart';
import '../shared/empty_state.dart';

/// Manages git stashes for a repository.
class StashManager extends ConsumerStatefulWidget {
  /// Local path of the repository.
  final String repoDir;

  /// Creates a [StashManager].
  const StashManager({super.key, required this.repoDir});

  @override
  ConsumerState<StashManager> createState() => _StashManagerState();
}

class _StashManagerState extends ConsumerState<StashManager> {
  List<VcsStash>? _stashes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStashes();
  }

  Future<void> _loadStashes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gitService = ref.read(gitServiceProvider);
      final stashes = await gitService.stashList(widget.repoDir);
      if (mounted) {
        setState(() {
          _stashes = stashes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _stashChanges() async {
    try {
      final gitService = ref.read(gitServiceProvider);
      await gitService.stashPush(widget.repoDir);
      ref.invalidate(selectedRepoStatusProvider);
      await _loadStashes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stash failed: $e')),
        );
      }
    }
  }

  Future<void> _pop(int index) async {
    try {
      final gitService = ref.read(gitServiceProvider);
      await gitService.stashPop(widget.repoDir, index: index);
      ref.invalidate(selectedRepoStatusProvider);
      await _loadStashes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pop failed: $e')),
        );
      }
    }
  }

  Future<void> _drop(int index) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Drop Stash',
      message: 'Are you sure you want to drop stash@{$index}? This cannot be undone.',
      confirmLabel: 'Drop',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final gitService = ref.read(gitServiceProvider);
      await gitService.stashDrop(widget.repoDir, index);
      await _loadStashes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drop failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Stashes',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _stashChanges,
                icon: const Icon(Icons.archive, size: 16),
                label: const Text('Stash Changes',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(color: CodeOpsColors.border, height: 1),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
        ),
      );
    }
    final stashes = _stashes ?? [];
    if (stashes.isEmpty) {
      return const EmptyState(
        icon: Icons.archive_outlined,
        title: 'No Stashes',
        subtitle: 'Your stash list is empty.',
      );
    }
    return ListView.builder(
      itemCount: stashes.length,
      itemBuilder: (context, index) {
        final stash = stashes[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: CodeOpsColors.surfaceVariant,
            child: Text(
              '${stash.index}',
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ),
          title: Text(
            stash.message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
            ),
          ),
          subtitle: stash.branch != null
              ? Text(
                  'on ${stash.branch}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore, size: 18),
                tooltip: 'Pop',
                color: CodeOpsColors.success,
                onPressed: () => _pop(stash.index),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Drop',
                color: CodeOpsColors.error,
                onPressed: () => _drop(stash.index),
              ),
            ],
          ),
        );
      },
    );
  }
}
