/// Encryption playground for transit key operations.
///
/// Provides a key selector dropdown and four operation tabs:
/// **Encrypt** (plaintext → ciphertext), **Decrypt** (ciphertext → plaintext),
/// **Rewrap** (ciphertext → new ciphertext), and **Data Key** (generate
/// plaintext + wrapped key pair). Each operation has input/output text areas
/// with copy-to-clipboard support and error display.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// An interactive encryption/decryption playground using transit keys.
class EncryptionPlayground extends ConsumerStatefulWidget {
  /// Creates an [EncryptionPlayground].
  const EncryptionPlayground({super.key});

  @override
  ConsumerState<EncryptionPlayground> createState() =>
      _EncryptionPlaygroundState();
}

class _EncryptionPlaygroundState extends ConsumerState<EncryptionPlayground>
    with SingleTickerProviderStateMixin {
  late TabController _opTabController;
  String? _selectedKeyName;

  // Encrypt
  final _encryptInputController = TextEditingController();
  String? _encryptOutput;
  bool _encrypting = false;
  String? _encryptError;

  // Decrypt
  final _decryptInputController = TextEditingController();
  String? _decryptOutput;
  bool _decrypting = false;
  String? _decryptError;

  // Rewrap
  final _rewrapInputController = TextEditingController();
  String? _rewrapOutput;
  bool _rewrapping = false;
  String? _rewrapError;

  // Data Key
  String? _dataKeyPlaintext;
  String? _dataKeyCiphertext;
  bool _generatingDataKey = false;
  String? _dataKeyError;

  @override
  void initState() {
    super.initState();
    _opTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _opTabController.dispose();
    _encryptInputController.dispose();
    _decryptInputController.dispose();
    _rewrapInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(vaultTransitKeysProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Encryption Playground',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Encrypt, decrypt, and rewrap data using named transit keys.',
          style: TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        // Key selector
        _buildKeySelector(keysAsync),
        const SizedBox(height: 16),
        // Operation tabs
        _buildOperationTabs(),
      ],
    );
  }

  Widget _buildKeySelector(AsyncValue<dynamic> keysAsync) {
    return keysAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Failed to load keys: $e',
        style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
      ),
      data: (page) {
        final keys = (page.content as List).cast<TransitKeyResponse>();
        if (keys.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: const Text(
              'No transit keys available. Create a key first.',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          );
        }

        // Auto-select first key if none selected
        if (_selectedKeyName == null && keys.isNotEmpty) {
          _selectedKeyName = keys.first.name;
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedKeyName,
          decoration: const InputDecoration(
            labelText: 'Transit Key',
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
          ),
          items: keys
              .map((k) => DropdownMenuItem(
                    value: k.name,
                    child: Text(
                      '${k.name}  (v${k.currentVersion}, ${k.algorithm})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedKeyName = v);
          },
          dropdownColor: CodeOpsColors.surface,
        );
      },
    );
  }

  Widget _buildOperationTabs() {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _opTabController,
            labelColor: CodeOpsColors.primary,
            unselectedLabelColor: CodeOpsColors.textTertiary,
            indicatorColor: CodeOpsColors.primary,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Encrypt'),
              Tab(text: 'Decrypt'),
              Tab(text: 'Rewrap'),
              Tab(text: 'Data Key'),
            ],
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          SizedBox(
            height: 340,
            child: TabBarView(
              controller: _opTabController,
              children: [
                _buildEncryptTab(),
                _buildDecryptTab(),
                _buildRewrapTab(),
                _buildDataKeyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encrypt Tab
  // ---------------------------------------------------------------------------

  Widget _buildEncryptTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plaintext (Base64-encoded)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _encryptInputController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter plaintext to encrypt...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(10),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _encrypting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outlined, size: 16),
              label: const Text('Encrypt'),
              onPressed:
                  _encrypting || _selectedKeyName == null ? null : _encrypt,
            ),
          ),
          if (_encryptError != null) ...[
            const SizedBox(height: 6),
            Text(
              _encryptError!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_encryptOutput != null) ...[
            const SizedBox(height: 8),
            _outputBox('Ciphertext', _encryptOutput!),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Decrypt Tab
  // ---------------------------------------------------------------------------

  Widget _buildDecryptTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ciphertext',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _decryptInputController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter ciphertext to decrypt...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(10),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _decrypting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text('Decrypt'),
              onPressed:
                  _decrypting || _selectedKeyName == null ? null : _decrypt,
            ),
          ),
          if (_decryptError != null) ...[
            const SizedBox(height: 6),
            Text(
              _decryptError!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_decryptOutput != null) ...[
            const SizedBox(height: 8),
            _outputBox('Plaintext', _decryptOutput!),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rewrap Tab
  // ---------------------------------------------------------------------------

  Widget _buildRewrapTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ciphertext to Rewrap',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _rewrapInputController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter ciphertext to rewrap with current key version...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(10),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _rewrapping
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew, size: 16),
              label: const Text('Rewrap'),
              onPressed:
                  _rewrapping || _selectedKeyName == null ? null : _rewrap,
            ),
          ),
          if (_rewrapError != null) ...[
            const SizedBox(height: 6),
            Text(
              _rewrapError!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_rewrapOutput != null) ...[
            const SizedBox(height: 8),
            _outputBox('Rewrapped Ciphertext', _rewrapOutput!),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Data Key Tab
  // ---------------------------------------------------------------------------

  Widget _buildDataKeyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Data Key',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generates a new data encryption key wrapped with the selected transit key.',
            style: TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _generatingDataKey
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.vpn_key, size: 16),
              label: const Text('Generate Data Key'),
              onPressed: _generatingDataKey || _selectedKeyName == null
                  ? null
                  : _generateDataKey,
            ),
          ),
          if (_dataKeyError != null) ...[
            const SizedBox(height: 6),
            Text(
              _dataKeyError!,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
          if (_dataKeyPlaintext != null) ...[
            const SizedBox(height: 8),
            _outputBox('Plaintext Key', _dataKeyPlaintext!),
          ],
          if (_dataKeyCiphertext != null) ...[
            const SizedBox(height: 8),
            _outputBox('Wrapped Key', _dataKeyCiphertext!),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Output box helper
  // ---------------------------------------------------------------------------

  Widget _outputBox(String label, String value) {
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

  // ---------------------------------------------------------------------------
  // API operations
  // ---------------------------------------------------------------------------

  Future<void> _encrypt() async {
    if (_encryptInputController.text.trim().isEmpty) return;
    setState(() {
      _encrypting = true;
      _encryptOutput = null;
      _encryptError = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.transitEncrypt(
        keyName: _selectedKeyName!,
        plaintext: _encryptInputController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _encryptOutput = result.ciphertext;
          _encrypting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _encryptError = e.toString();
          _encrypting = false;
        });
      }
    }
  }

  Future<void> _decrypt() async {
    if (_decryptInputController.text.trim().isEmpty) return;
    setState(() {
      _decrypting = true;
      _decryptOutput = null;
      _decryptError = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.transitDecrypt(
        keyName: _selectedKeyName!,
        ciphertext: _decryptInputController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _decryptOutput = result.plaintext;
          _decrypting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _decryptError = e.toString();
          _decrypting = false;
        });
      }
    }
  }

  Future<void> _rewrap() async {
    if (_rewrapInputController.text.trim().isEmpty) return;
    setState(() {
      _rewrapping = true;
      _rewrapOutput = null;
      _rewrapError = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.transitRewrap(
        keyName: _selectedKeyName!,
        ciphertext: _rewrapInputController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _rewrapOutput = result.ciphertext;
          _rewrapping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rewrapError = e.toString();
          _rewrapping = false;
        });
      }
    }
  }

  Future<void> _generateDataKey() async {
    setState(() {
      _generatingDataKey = true;
      _dataKeyPlaintext = null;
      _dataKeyCiphertext = null;
      _dataKeyError = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.generateDataKey(_selectedKeyName!);
      if (mounted) {
        setState(() {
          _dataKeyPlaintext = result['plaintext'];
          _dataKeyCiphertext = result['ciphertext'];
          _generatingDataKey = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dataKeyError = e.toString();
          _generatingDataKey = false;
        });
      }
    }
  }
}
