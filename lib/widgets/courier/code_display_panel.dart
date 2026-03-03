/// Code display panel for viewing generated code snippets.
///
/// Shows generated code with line numbers, copy-to-clipboard, save-to-file,
/// word-wrap toggle, and a variables toggle (show raw `{{variables}}` vs
/// resolved values).
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/courier_enums.dart';
import '../../services/courier/code_generation_service.dart';
import '../../theme/colors.dart';

/// Displays a generated code snippet with toolbar actions.
///
/// Toolbar contains: copy, save, word-wrap toggle, and variables toggle.
/// Code is displayed in a scrollable, read-only monospace view with line
/// numbers.
class CodeDisplayPanel extends StatefulWidget {
  /// The generated code string.
  final String code;

  /// The target language (used for file extension when saving).
  final CodeLanguage language;

  /// Callback when the variables toggle is changed.
  final ValueChanged<bool>? onVariablesToggled;

  /// Whether to show resolved variable values (true) or raw `{{var}}` (false).
  final bool showResolved;

  /// Creates a [CodeDisplayPanel].
  const CodeDisplayPanel({
    super.key,
    required this.code,
    required this.language,
    this.onVariablesToggled,
    this.showResolved = false,
  });

  @override
  State<CodeDisplayPanel> createState() => _CodeDisplayPanelState();
}

class _CodeDisplayPanelState extends State<CodeDisplayPanel> {
  bool _wordWrap = false;
  final _scrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
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

  Future<void> _saveToFile() async {
    final svc = const CodeGenerationService();
    final ext = svc.fileExtension(widget.language);
    final defaultName = 'request.$ext';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Code Snippet',
      fileName: defaultName,
      allowedExtensions: [ext],
      type: FileType.custom,
    );
    if (result == null) return;
    await File(result).writeAsString(widget.code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $result'),
          duration: const Duration(seconds: 2),
          backgroundColor: CodeOpsColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.code.split('\n');
    final lineCount = lines.length;
    final gutterWidth = '$lineCount'.length * 10.0 + 24;

    return Column(
      key: const Key('code_display_panel'),
      children: [
        // ── Toolbar ──────────────────────────────────────────────────
        Container(
          key: const Key('code_toolbar'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surface,
            border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          child: Row(
            children: [
              Text(
                widget.language.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),

              // Variables toggle
              if (widget.onVariablesToggled != null) ...[
                const Text(
                  'Resolved',
                  style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 24,
                  child: Switch(
                    key: const Key('variables_toggle'),
                    value: widget.showResolved,
                    onChanged: widget.onVariablesToggled,
                    activeTrackColor: CodeOpsColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Word wrap toggle
              Tooltip(
                message: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
                child: IconButton(
                  key: const Key('word_wrap_toggle'),
                  icon: const Icon(Icons.wrap_text, size: 18),
                  color: _wordWrap ? CodeOpsColors.primary : CodeOpsColors.textTertiary,
                  onPressed: () => setState(() => _wordWrap = !_wordWrap),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              const SizedBox(width: 4),

              // Save button
              Tooltip(
                message: 'Save to file',
                child: IconButton(
                  key: const Key('save_button'),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  color: CodeOpsColors.textSecondary,
                  onPressed: _saveToFile,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              const SizedBox(width: 4),

              // Copy button (prominent)
              FilledButton.icon(
                key: const Key('copy_button'),
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),

        // ── Code area ────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: CodeOpsColors.background,
            child: widget.code.isEmpty
                ? const Center(
                    key: Key('code_empty'),
                    child: Text(
                      'Select a language to generate code',
                      style: TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: _wordWrap
                        ? ListView.builder(
                            key: const Key('code_content'),
                            controller: _scrollController,
                            itemCount: lineCount,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (_, i) => _buildLine(i, lines[i], gutterWidth),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _horizontalScrollController,
                              child: Column(
                                key: const Key('code_content'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  for (var i = 0; i < lineCount; i++)
                                    _buildLine(i, lines[i], gutterWidth),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int index, String line, double gutterWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line number gutter
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
                height: 1.5,
              ),
            ),
          ),
        ),
        // Code line
        if (_wordWrap)
          Expanded(
            child: SelectableText(
              line,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
                height: 1.5,
              ),
            ),
          )
        else
          SelectableText(
            line,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              color: CodeOpsColors.textPrimary,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}
