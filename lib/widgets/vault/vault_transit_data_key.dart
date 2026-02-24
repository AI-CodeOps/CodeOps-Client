/// Data key generation panel for transit encryption.
///
/// Generates a new data encryption key wrapped with the selected
/// transit key. Outputs both the plaintext key (for immediate use)
/// and the wrapped/encrypted key (for storage). Includes a warning
/// banner about handling the plaintext key carefully.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// The Data Key tab of the transit operations panel.
class VaultTransitDataKey extends ConsumerStatefulWidget {
  /// Name of the transit key to wrap with.
  final String keyName;

  /// Creates a [VaultTransitDataKey].
  const VaultTransitDataKey({super.key, required this.keyName});

  @override
  ConsumerState<VaultTransitDataKey> createState() =>
      _VaultTransitDataKeyState();
}

class _VaultTransitDataKeyState
    extends ConsumerState<VaultTransitDataKey> {
  String? _plaintextKey;
  String? _wrappedKey;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Generate Data Encryption Key',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generates a new data encryption key wrapped with the '
            'selected transit key for envelope encryption.',
            style: TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.vpn_key, size: 16),
              label: const Text('Generate Data Key'),
              onPressed: _loading ? null : _generateDataKey,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_plaintextKey != null || _wrappedKey != null) ...[
            const SizedBox(height: 12),
            // Warning banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CodeOpsColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: CodeOpsColors.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The plaintext key is shown once. Store the encrypted '
                      'key for later retrieval.',
                      style: TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_plaintextKey != null) ...[
            const SizedBox(height: 12),
            _OutputBox(label: 'Plaintext Key', value: _plaintextKey!),
          ],
          if (_wrappedKey != null) ...[
            const SizedBox(height: 8),
            _OutputBox(label: 'Wrapped Key (encrypted)', value: _wrappedKey!),
          ],
        ],
      ),
    );
  }

  Future<void> _generateDataKey() async {
    setState(() {
      _loading = true;
      _plaintextKey = null;
      _wrappedKey = null;
      _error = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.generateDataKey(widget.keyName);
      if (mounted) {
        setState(() {
          _plaintextKey = result['plaintext'];
          _wrappedKey = result['ciphertext'];
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
