/// DBeaver-style DDL display for the Properties panel.
///
/// Shows the table's CREATE TABLE DDL statement in a read-only, monospace
/// code view with a copy-to-clipboard button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// The DDL sub-tab within the Properties panel.
///
/// Shows the CREATE TABLE / CREATE VIEW DDL in a scrollable, monospace code
/// area with a toolbar containing a copy button.
class DdlTab extends ConsumerWidget {
  /// Creates a [DdlTab].
  const DdlTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddlAsync = ref.watch(datalensDdlProvider);

    return ddlAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: CodeOpsColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error loading DDL: $error',
          style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
        ),
      ),
      data: (ddl) {
        if (ddl == null || ddl.isEmpty) {
          return const Center(
            child: Text(
              'No DDL available',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          );
        }

        return _buildDdlView(context, ddl);
      },
    );
  }

  /// Builds the DDL code view with toolbar and scrollable content.
  Widget _buildDdlView(BuildContext context, String ddl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          color: CodeOpsColors.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const Text(
                'DDL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
              const Spacer(),
              _CopyButton(ddl: ddl),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        // DDL content
        Expanded(
          child: Container(
            color: CodeOpsColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                ddl,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Copy-to-clipboard button with visual feedback.
class _CopyButton extends StatefulWidget {
  /// The DDL text to copy.
  final String ddl;

  const _CopyButton({required this.ddl});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 16,
        color: _copied ? CodeOpsColors.success : CodeOpsColors.textSecondary,
      ),
      tooltip: 'Copy DDL to clipboard',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.ddl));
        if (mounted) {
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        }
      },
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
