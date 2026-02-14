/// Branch picker dropdown with search and current-branch indicator.
///
/// Shows a dropdown of branches with a lock icon for protected branches.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/github_providers.dart';
import '../../theme/colors.dart';

/// A branch selection dropdown for a repository.
class BranchPicker extends ConsumerStatefulWidget {
  /// Full name (owner/repo) of the repository.
  final String repoFullName;

  /// Current branch name.
  final String currentBranch;

  /// Called when a branch is selected.
  final ValueChanged<String> onBranchSelected;

  /// Creates a [BranchPicker].
  const BranchPicker({
    super.key,
    required this.repoFullName,
    required this.currentBranch,
    required this.onBranchSelected,
  });

  @override
  ConsumerState<BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends ConsumerState<BranchPicker> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(repoBranchesProvider(widget.repoFullName));

    return branchesAsync.when(
      loading: () => const SizedBox(
        height: 32,
        width: 120,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Chip(
        label: Text(
          widget.currentBranch,
          style: const TextStyle(fontSize: 12),
        ),
        avatar: const Icon(Icons.call_split, size: 14),
      ),
      data: (branches) {
        final filtered = _filter.isEmpty
            ? branches
            : branches
                .where((b) =>
                    b.name.toLowerCase().contains(_filter.toLowerCase()))
                .toList();

        return PopupMenuButton<String>(
          tooltip: 'Switch branch',
          offset: const Offset(0, 36),
          color: CodeOpsColors.surface,
          onSelected: widget.onBranchSelected,
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              enabled: false,
              height: 40,
              child: SizedBox(
                width: 200,
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Filter branches...',
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
            ),
            const PopupMenuDivider(),
            ...filtered.map((b) => PopupMenuItem<String>(
                  value: b.name,
                  child: Row(
                    children: [
                      if (b.name == widget.currentBranch)
                        const Icon(Icons.check, size: 16,
                            color: CodeOpsColors.success)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.name,
                          style: TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 13,
                            fontWeight: b.name == widget.currentBranch
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (b.isProtected)
                        const Icon(Icons.lock, size: 14,
                            color: CodeOpsColors.warning),
                    ],
                  ),
                )),
          ],
          child: Chip(
            label: Text(
              widget.currentBranch,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
            avatar: const Icon(Icons.call_split, size: 14,
                color: CodeOpsColors.textTertiary),
            backgroundColor: CodeOpsColors.surfaceVariant,
            side: BorderSide.none,
          ),
        );
      },
    );
  }
}
