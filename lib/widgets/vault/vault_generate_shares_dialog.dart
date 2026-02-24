/// Dialog for generating and displaying Shamir key shares.
///
/// Calls the generate shares API and displays each share with individual
/// copy buttons, a "Copy All" button, and a "Download as Text File" option.
/// The dialog cannot be dismissed without checking the "I have saved all
/// shares" checkbox.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// Shows a [VaultGenerateSharesDialog] with the given generated shares.
Future<void> showGenerateSharesDialog(
  BuildContext context, {
  required List<String> shares,
  required int totalShares,
  required int threshold,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => VaultGenerateSharesDialog(
      shares: shares,
      totalShares: totalShares,
      threshold: threshold,
    ),
  );
}

/// A dialog that displays generated Shamir key shares.
///
/// Each share is shown with an index label and individual copy button.
/// Provides "Copy All" and "Download as Text File" actions. Cannot be
/// dismissed until the user checks the "I have saved all shares" checkbox.
class VaultGenerateSharesDialog extends StatefulWidget {
  /// The generated key shares.
  final List<String> shares;

  /// Total number of shares generated.
  final int totalShares;

  /// Number of shares required to unseal.
  final int threshold;

  /// Creates a [VaultGenerateSharesDialog].
  const VaultGenerateSharesDialog({
    super.key,
    required this.shares,
    required this.totalShares,
    required this.threshold,
  });

  @override
  State<VaultGenerateSharesDialog> createState() =>
      _VaultGenerateSharesDialogState();
}

class _VaultGenerateSharesDialogState extends State<VaultGenerateSharesDialog> {
  bool _savedConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Generated Key Shares'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CodeOpsColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: CodeOpsColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: CodeOpsColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These shares will not be shown again. Copy and '
                        'securely store each share before closing this dialog.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Info
              Text(
                'Total Shares: ${widget.totalShares}  •  '
                'Threshold: ${widget.threshold}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // Share list
              ...widget.shares.asMap().entries.map(
                    (entry) => _ShareRow(
                      index: entry.key + 1,
                      share: entry.value,
                    ),
                  ),
              const SizedBox(height: 16),
              // Copy All + Download
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all, size: 14),
                    label: const Text('Copy All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.primary,
                      side: const BorderSide(color: CodeOpsColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _copyAll,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download as Text File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.primary,
                      side: const BorderSide(color: CodeOpsColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _downloadFile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Confirmation checkbox
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _savedConfirmed,
                      onChanged: (v) =>
                          setState(() => _savedConfirmed = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'I have saved all shares',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed:
              _savedConfirmed ? () => Navigator.of(context).pop() : null,
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: widget.shares.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All shares copied to clipboard')),
    );
  }

  Future<void> _downloadFile() async {
    final content = StringBuffer()
      ..writeln('Vault Key Shares')
      ..writeln('Total Shares: ${widget.totalShares}')
      ..writeln('Threshold: ${widget.threshold}')
      ..writeln('---');
    for (var i = 0; i < widget.shares.length; i++) {
      content.writeln('Share ${i + 1}: ${widget.shares[i]}');
    }

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Key Shares',
      fileName: 'vault-key-shares.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      final file = File(result);
      await file.writeAsString(content.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shares saved to file')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Share Row
// ---------------------------------------------------------------------------

class _ShareRow extends StatelessWidget {
  final int index;
  final String share;

  const _ShareRow({required this.index, required this.share});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Share $index',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              share,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            tooltip: 'Copy share $index',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: share));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share $index copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
