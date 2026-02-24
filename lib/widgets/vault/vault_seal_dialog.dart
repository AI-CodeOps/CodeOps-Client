/// Type-to-confirm dialog for sealing the Vault.
///
/// Requires the user to type "SEAL" before the confirm button is enabled.
/// Displays a warning about the impact of sealing and includes the
/// threshold/total shares configuration.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Shows a [VaultSealDialog] and returns `true` if confirmed.
Future<bool?> showVaultSealDialog(
  BuildContext context, {
  required int threshold,
  required int totalShares,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => VaultSealDialog(
      threshold: threshold,
      totalShares: totalShares,
    ),
  );
}

/// A type-to-confirm dialog for sealing the Vault.
///
/// Displays a warning about the consequences of sealing and requires the
/// user to type "SEAL" to enable the confirm button. Shows the number of
/// shares required to unseal.
class VaultSealDialog extends StatefulWidget {
  /// Number of shares required to unseal.
  final int threshold;

  /// Total number of key shares.
  final int totalShares;

  /// Creates a [VaultSealDialog].
  const VaultSealDialog({
    super.key,
    required this.threshold,
    required this.totalShares,
  });

  @override
  State<VaultSealDialog> createState() => _VaultSealDialogState();
}

class _VaultSealDialogState extends State<VaultSealDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Seal Vault'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seal the vault? All vault operations will be unavailable '
              'until unsealed.',
              style: TextStyle(color: CodeOpsColors.textSecondary),
            ),
            const SizedBox(height: 8),
            // Warning banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CodeOpsColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      size: 16, color: CodeOpsColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unsealing requires ${widget.threshold} of '
                      '${widget.totalShares} key shares.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Type SEAL to confirm:',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              onChanged: (value) {
                setState(() => _valid = value.trim() == 'SEAL');
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _valid ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.error,
          ),
          child: const Text('Seal'),
        ),
      ],
    );
  }
}
