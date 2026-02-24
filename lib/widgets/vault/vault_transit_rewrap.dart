/// Rewrap operation panel for transit encryption.
///
/// Re-encrypts ciphertext with the current key version without
/// exposing the plaintext. Includes inline help text explaining
/// the rewrap use case and a copy-to-clipboard button on the output.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// The Rewrap tab of the transit operations panel.
class VaultTransitRewrap extends ConsumerStatefulWidget {
  /// Name of the transit key to use.
  final String keyName;

  /// Creates a [VaultTransitRewrap].
  const VaultTransitRewrap({super.key, required this.keyName});

  @override
  ConsumerState<VaultTransitRewrap> createState() =>
      _VaultTransitRewrapState();
}

class _VaultTransitRewrapState
    extends ConsumerState<VaultTransitRewrap> {
  final _inputController = TextEditingController();
  String? _output;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Help text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CodeOpsColors.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CodeOpsColors.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: CodeOpsColors.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rewrap re-encrypts data with the latest key version '
                    'without exposing the plaintext. Use after key rotation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ciphertext to Rewrap',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Enter ciphertext encrypted with an older key version...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew, size: 16),
              label: const Text('Rewrap'),
              onPressed: _loading ? null : _rewrap,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_output != null) ...[
            const SizedBox(height: 8),
            _OutputBox(label: 'Rewrapped Ciphertext', value: _output!),
          ],
        ],
      ),
    );
  }

  Future<void> _rewrap() async {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _output = null;
      _error = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.transitRewrap(
        keyName: widget.keyName,
        ciphertext: _inputController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _output = result.ciphertext;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }
}

/// A read-only output box with a copy button.
class _OutputBox extends StatelessWidget {
  final String label;
  final String value;

  const _OutputBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied to clipboard')),
                );
              },
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxHeight: 80),
          decoration: BoxDecoration(
            color: CodeOpsColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
