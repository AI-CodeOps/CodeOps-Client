/// Value tab for the Vault secret detail page (CVF-003).
///
/// Displays the secret value using [ScribeEditor] with JSON auto-detection,
/// a key-value pair table toggle for JSON objects, reveal/hide with 30-second
/// auto-hide, clipboard copy, and an edit mode that creates new versions.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';

/// Determines if a string is valid JSON.
bool _isJson(String value) {
  try {
    json.decode(value);
    return true;
  } catch (_) {
    return false;
  }
}

/// Determines if a string is a JSON object (for KV editor).
bool _isJsonObject(String value) {
  try {
    final decoded = json.decode(value);
    return decoded is Map;
  } catch (_) {
    return false;
  }
}

/// Formats JSON with indentation for display.
String _prettyJson(String value) {
  try {
    final decoded = json.decode(value);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return value;
  }
}

/// The Value tab of the secret detail page.
///
/// Shows a reveal/hide flow with ScribeEditor for syntax-highlighted
/// display, JSON auto-detection, key-value table toggle for JSON
/// objects, and an edit mode to create new secret versions.
class VaultSecretValueTab extends ConsumerStatefulWidget {
  /// The secret ID to display the value for.
  final String secretId;

  /// Creates a [VaultSecretValueTab].
  const VaultSecretValueTab({super.key, required this.secretId});

  @override
  ConsumerState<VaultSecretValueTab> createState() =>
      _VaultSecretValueTabState();
}

class _VaultSecretValueTabState extends ConsumerState<VaultSecretValueTab> {
  String? _revealedValue;
  Timer? _autoHideTimer;
  bool _loading = false;
  bool _editing = false;
  bool _saving = false;
  bool _showKvEditor = false;
  String _editedValue = '';
  final _descController = TextEditingController();

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealedValue == null) {
      return _buildHiddenState();
    }

    return _buildRevealedState();
  }

  // ─── Hidden state ──────────────────────────────────────────────────────

  Widget _buildHiddenState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_off,
            size: 48,
            color: CodeOpsColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Secret value is hidden',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Value will auto-hide after 30 seconds',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility, size: 16),
            label: const Text('Reveal Secret'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.warning,
            ),
            onPressed: _loading ? null : _revealSecret,
          ),
        ],
      ),
    );
  }

  // ─── Revealed state ────────────────────────────────────────────────────

  Widget _buildRevealedState() {
    final value = _editing ? _editedValue : _revealedValue!;
    final isJsonValue = _isJson(value);
    final isJsonObj = _isJsonObject(value);
    final language = isJsonValue ? 'json' : 'plaintext';

    return Column(
      children: [
        // Toolbar.
        _buildToolbar(isJsonObj),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Content.
        Expanded(
          child: _showKvEditor && isJsonObj
              ? _buildKvEditor(value)
              : _buildEditorView(value, language),
        ),
        // Edit mode footer.
        if (_editing) _buildEditFooter(),
      ],
    );
  }

  Widget _buildToolbar(bool isJsonObj) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            size: 14,
            color: CodeOpsColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            _editing
                ? 'Edit mode — save creates a new version'
                : 'Secret revealed — auto-hides in 30s',
            style: TextStyle(
              fontSize: 11,
              color:
                  _editing ? CodeOpsColors.primary : CodeOpsColors.warning,
            ),
          ),
          const Spacer(),
          // KV toggle (only for JSON objects).
          if (isJsonObj && !_editing)
            IconButton(
              icon: Icon(
                _showKvEditor ? Icons.code : Icons.table_chart,
                size: 16,
              ),
              tooltip: _showKvEditor ? 'Show JSON' : 'Show Key-Value Table',
              onPressed: () => setState(() => _showKvEditor = !_showKvEditor),
            ),
          if (!_editing) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              tooltip: 'Edit value',
              onPressed: _enterEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copy to clipboard',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.visibility_off, size: 16),
              tooltip: 'Hide',
              onPressed: _hideValue,
            ),
          ] else ...[
            TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorView(String value, String language) {
    final displayValue = language == 'json' ? _prettyJson(value) : value;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ScribeEditor(
        content: displayValue,
        language: language,
        readOnly: !_editing,
        showLineNumbers: true,
        showCodeFolding: language == 'json',
        onChanged: _editing ? (v) => setState(() => _editedValue = v) : null,
      ),
    );
  }

  Widget _buildKvEditor(String value) {
    Map<String, dynamic> kvMap;
    try {
      kvMap = json.decode(value) as Map<String, dynamic>;
    } catch (_) {
      kvMap = {};
    }

    if (kvMap.isEmpty) {
      return const Center(
        child: Text(
          'Empty JSON object',
          style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header row.
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Key',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Value',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        ...kvMap.entries.map((entry) => _KvRow(
              kvKey: entry.key,
              kvValue: _formatKvValue(entry.value),
            )),
      ],
    );
  }

  String _formatKvValue(dynamic value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  Widget _buildEditFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Change description (optional)',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 16),
            label: const Text('Save New Version'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
            ),
            onPressed: _saving ? null : _saveNewVersion,
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _revealSecret() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(vaultApiProvider);
      final value = await api.readSecretValue(widget.secretId);
      if (mounted) {
        setState(() {
          _revealedValue = value.value;
          _loading = false;
          _showKvEditor = false;
          _editing = false;
        });
        _startAutoHide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reveal: $e')),
        );
      }
    }
  }

  void _startAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_editing) _hideValue();
    });
  }

  void _hideValue() {
    _autoHideTimer?.cancel();
    setState(() {
      _revealedValue = null;
      _editing = false;
      _showKvEditor = false;
    });
  }

  void _copyToClipboard() {
    if (_revealedValue == null) return;
    Clipboard.setData(ClipboardData(text: _revealedValue!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Secret value copied to clipboard')),
    );
  }

  void _enterEditMode() {
    _autoHideTimer?.cancel();
    setState(() {
      _editing = true;
      _editedValue = _revealedValue!;
      _descController.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _editedValue = '';
    });
    _startAutoHide();
  }

  Future<void> _saveNewVersion() async {
    if (_editedValue.isEmpty) return;
    setState(() => _saving = true);

    try {
      final api = ref.read(vaultApiProvider);
      final desc = _descController.text.trim();
      await api.updateSecret(
        widget.secretId,
        value: _editedValue,
        changeDescription: desc.isEmpty ? null : desc,
      );

      ref.invalidate(vaultSecretDetailProvider(widget.secretId));
      ref.invalidate(vaultSecretVersionsProvider(widget.secretId));
      ref.invalidate(vaultSecretsProvider);

      if (mounted) {
        setState(() {
          _revealedValue = _editedValue;
          _editing = false;
          _saving = false;
        });
        _startAutoHide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New version created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// KV Row
// ---------------------------------------------------------------------------

class _KvRow extends StatelessWidget {
  final String kvKey;
  final String kvValue;

  const _KvRow({required this.kvKey, required this.kvValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              kvKey,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SelectableText(
              kvValue,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
