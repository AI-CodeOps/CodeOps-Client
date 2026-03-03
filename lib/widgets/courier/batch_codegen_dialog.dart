/// Dialog for batch code generation across an entire collection.
///
/// Allows the user to select a collection, choose a target language, pick an
/// output format (single file or ZIP), and generate code for every request in
/// the collection via the server API.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../models/courier_models.dart';
import '../../providers/courier_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';

/// Output format for batch code generation.
enum BatchOutputFormat {
  /// All requests concatenated into a single file.
  singleFile,

  /// One file per request (conceptually a ZIP — copied as text for now).
  perRequest,
}

/// Dialog for generating code snippets for all requests in a collection.
///
/// Uses the server-side `POST /courier/codegen/generate/all` endpoint for
/// batch generation. Results are copied to the clipboard.
class BatchCodegenDialog extends ConsumerStatefulWidget {
  /// Creates a [BatchCodegenDialog].
  const BatchCodegenDialog({super.key});

  @override
  ConsumerState<BatchCodegenDialog> createState() => _BatchCodegenDialogState();
}

class _BatchCodegenDialogState extends ConsumerState<BatchCodegenDialog> {
  String? _selectedCollectionId;
  CodeLanguage _selectedLanguage = CodeLanguage.curl;
  BatchOutputFormat _outputFormat = BatchOutputFormat.singleFile;
  bool _generating = false;
  String? _generatedCode;
  String? _error;

  Future<void> _generate() async {
    if (_selectedCollectionId == null) return;
    setState(() {
      _generating = true;
      _error = null;
      _generatedCode = null;
    });

    try {
      final teamId = ref.read(selectedTeamIdProvider);
      if (teamId == null) throw Exception('No team selected');
      final api = ref.read(courierApiProvider);

      // Fetch collection tree to get all request IDs.
      final folders = await api.getCollectionTree(teamId, _selectedCollectionId!);
      final requestIds = <String>[];
      for (final folder in folders) {
        _collectFolderRequestIds(folder, requestIds);
      }

      if (requestIds.isEmpty) {
        setState(() {
          _generating = false;
          _error = 'No requests found in collection';
        });
        return;
      }

      // Generate code for each request.
      final snippets = <String>[];
      for (final reqId in requestIds) {
        final result = await api.generateCode(
          teamId,
          GenerateCodeRequest(
            requestId: reqId,
            language: _selectedLanguage,
          ),
        );
        if (result.code != null && result.code!.isNotEmpty) {
          snippets.add(result.code!);
        }
      }

      setState(() {
        _generating = false;
        _generatedCode = snippets.join('\n\n${'─' * 60}\n\n');
      });
    } catch (e) {
      setState(() {
        _generating = false;
        _error = e.toString();
      });
    }
  }

  void _collectFolderRequestIds(FolderTreeResponse folder, List<String> ids) {
    if (folder.requests != null) {
      for (final r in folder.requests!) {
        if (r.id != null) ids.add(r.id!);
      }
    }
    if (folder.subFolders != null) {
      for (final f in folder.subFolders!) {
        _collectFolderRequestIds(f, ids);
      }
    }
  }

  Future<void> _copyGenerated() async {
    if (_generatedCode == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
          backgroundColor: CodeOpsColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(courierCollectionsProvider);

    return Dialog(
      key: const Key('batch_codegen_dialog'),
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.code, color: CodeOpsColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Batch Code Generation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: CodeOpsColors.textTertiary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Collection selector ──────────────────────────────
              const Text(
                'Collection',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
              const SizedBox(height: 6),
              collections.when(
                data: (cols) => DropdownButtonFormField<String>(
                  key: const Key('batch_collection_selector'),
                  decoration: _inputDecoration('Select collection'),
                  dropdownColor: CodeOpsColors.surfaceVariant,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CodeOpsColors.textPrimary,
                  ),
                  initialValue: _selectedCollectionId,
                  items: cols
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name ?? 'Unnamed'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCollectionId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'Failed to load collections',
                  style: TextStyle(color: CodeOpsColors.error),
                ),
              ),
              const SizedBox(height: 16),

              // ── Language selector ────────────────────────────────
              const Text(
                'Language',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<CodeLanguage>(
                key: const Key('batch_language_selector'),
                decoration: _inputDecoration('Select language'),
                dropdownColor: CodeOpsColors.surfaceVariant,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
                initialValue: _selectedLanguage,
                items: CodeLanguage.values
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedLanguage = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Output format ────────────────────────────────────
              const Text(
                'Output Format',
                style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                key: const Key('batch_output_format'),
                children: [
                  _formatChip(
                    'Single File',
                    BatchOutputFormat.singleFile,
                    Icons.insert_drive_file_outlined,
                  ),
                  const SizedBox(width: 8),
                  _formatChip(
                    'Per Request',
                    BatchOutputFormat.perRequest,
                    Icons.folder_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Error ────────────────────────────────────────────
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
                ),
                const SizedBox(height: 12),
              ],

              // ── Generated code preview ───────────────────────────
              if (_generatedCode != null) ...[
                Container(
                  key: const Key('batch_code_preview'),
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _generatedCode!,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: CodeOpsColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Actions ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_generatedCode != null) ...[
                    FilledButton.icon(
                      key: const Key('batch_copy_button'),
                      onPressed: _copyGenerated,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy All'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CodeOpsColors.surfaceVariant,
                        foregroundColor: CodeOpsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.icon(
                    key: const Key('batch_generate_button'),
                    onPressed: _selectedCollectionId == null || _generating
                        ? null
                        : _generate,
                    icon: _generating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow, size: 16),
                    label: Text(_generating ? 'Generating...' : 'Generate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CodeOpsColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatChip(String label, BatchOutputFormat format, IconData icon) {
    final selected = _outputFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _outputFormat = format),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CodeOpsColors.primary.withValues(alpha: 0.15) : CodeOpsColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? CodeOpsColors.primary : CodeOpsColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? CodeOpsColors.primary : CodeOpsColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? CodeOpsColors.primary : CodeOpsColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: CodeOpsColors.textTertiary,
        ),
        filled: true,
        fillColor: CodeOpsColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}
