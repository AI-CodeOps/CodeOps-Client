/// Unified diff viewer widget.
///
/// Renders a side-by-side or unified diff with green additions,
/// red deletions, line numbers, and monospace font.
library;

import 'package:flutter/material.dart';

import '../../models/vcs_models.dart';
import '../../theme/colors.dart';

/// Displays a unified diff for one or more files.
class DiffViewer extends StatelessWidget {
  /// Diff results to render.
  final List<DiffResult> diffs;

  /// Creates a [DiffViewer].
  const DiffViewer({super.key, required this.diffs});

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) {
      return const Center(
        child: Text(
          'No changes to display',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: diffs.length,
      itemBuilder: (context, index) => _DiffFileBlock(diff: diffs[index]),
    );
  }
}

class _DiffFileBlock extends StatelessWidget {
  final DiffResult diff;

  const _DiffFileBlock({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File header.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: CodeOpsColors.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  diff.filePath,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (diff.isBinary)
                const Text(
                  'Binary',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                )
              else
                Text(
                  '+${diff.additions} -${diff.deletions}',
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        if (diff.isBinary)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Binary file changed',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          )
        else
          ...diff.hunks.map(_buildHunk),
        const Divider(color: CodeOpsColors.border, height: 1),
      ],
    );
  }

  Widget _buildHunk(DiffHunk hunk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hunk header.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: CodeOpsColors.primary.withValues(alpha: 0.08),
          child: Text(
            hunk.header,
            style: const TextStyle(
              color: CodeOpsColors.primary,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        // Diff lines.
        ...hunk.lines.map(_buildLine),
      ],
    );
  }

  Widget _buildLine(DiffLine line) {
    Color bg;
    Color fg;
    String prefix;

    switch (line.type) {
      case DiffLineType.addition:
        bg = const Color(0xFF0D3321);
        fg = CodeOpsColors.success;
        prefix = '+';
      case DiffLineType.deletion:
        bg = const Color(0xFF3D1518);
        fg = CodeOpsColors.error;
        prefix = '-';
      case DiffLineType.header:
        bg = Colors.transparent;
        fg = CodeOpsColors.primary;
        prefix = '@';
      case DiffLineType.context:
        bg = Colors.transparent;
        fg = CodeOpsColors.textSecondary;
        prefix = ' ';
    }

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Old line number.
          SizedBox(
            width: 40,
            child: Text(
              line.oldLineNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          // New line number.
          SizedBox(
            width: 40,
            child: Text(
              line.newLineNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Prefix.
          SizedBox(
            width: 12,
            child: Text(
              prefix,
              style: TextStyle(
                color: fg,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          // Content.
          Expanded(
            child: Text(
              line.content,
              style: TextStyle(
                color: fg,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
