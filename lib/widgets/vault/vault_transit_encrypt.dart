/// Encrypt operation panel for transit encryption.
///
/// Provides a text input for plaintext data, calls
/// [VaultApi.transitEncrypt], and displays the resulting ciphertext
/// with a copy-to-clipboard button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// The Encrypt tab of the transit operations panel.
class VaultTransitEncrypt extends ConsumerStatefulWidget {
  /// Name of the transit key to use.
  final String keyName;

  /// Creates a [VaultTransitEncrypt].
  const VaultTransitEncrypt({super.key, required this.keyName});

  @override
  ConsumerState<VaultTransitEncrypt> createState() =>
      _VaultTransitEncryptState();
}

class _VaultTransitEncryptState
    extends ConsumerState<VaultTransitEncrypt> {
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
          const Text(
            'Plaintext',
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
                hintText: 'Enter plaintext to encrypt...',
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
                  : const Icon(Icons.lock_outlined, size: 16),
              label: const Text('Encrypt'),
              onPressed: _loading ? null : _encrypt,
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
            _OutputBox(label: 'Ciphertext', value: _output!),
          ],
        ],
      ),
    );
  }

  Future<void> _encrypt() async {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _output = null;
      _error = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.transitEncrypt(
        keyName: widget.keyName,
        plaintext: _inputController.text.trim(),
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
