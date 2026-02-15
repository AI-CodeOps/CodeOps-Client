/// Markdown editor for persona content with toolbar and line numbers.
///
/// Provides formatting toolbar, monospace editing, and debounced
/// change notifications.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// A markdown text editor with toolbar, line numbers, and word count.
class PersonaEditorWidget extends StatefulWidget {
  /// Initial markdown content.
  final String initialContent;

  /// Called with updated content after debounce delay.
  final ValueChanged<String> onChanged;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Creates a [PersonaEditorWidget].
  const PersonaEditorWidget({
    super.key,
    required this.initialContent,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<PersonaEditorWidget> createState() => _PersonaEditorWidgetState();
}

class _PersonaEditorWidgetState extends State<PersonaEditorWidget> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _updateCounts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _controller.text;
    _charCount = text.length;
    _wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
    setState(_updateCounts);
  }

  void _insertMarkdown(String prefix, String suffix) {
    if (widget.readOnly) return;

    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isCollapsed) {
      final insert = '$prefix$suffix';
      _controller.text =
          text.replaceRange(selection.start, selection.end, insert);
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final replacement = '$prefix$selected$suffix';
      _controller.text =
          text.replaceRange(selection.start, selection.end, replacement);
      _controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selected.length,
      );
    }
    _onTextChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(_controller.text).length + 1;

    return Column(
      children: [
        // Toolbar.
        if (!widget.readOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
            ),
            child: Row(
              children: [
                _ToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onPressed: () => _insertMarkdown('**', '**'),
                ),
                _ToolbarButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onPressed: () => _insertMarkdown('*', '*'),
                ),
                _ToolbarButton(
                  icon: Icons.title,
                  tooltip: 'Heading',
                  onPressed: () => _insertMarkdown('## ', ''),
                ),
                _ToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'List',
                  onPressed: () => _insertMarkdown('- ', ''),
                ),
                _ToolbarButton(
                  icon: Icons.code,
                  tooltip: 'Code Block',
                  onPressed: () => _insertMarkdown('```\n', '\n```'),
                ),
                _ToolbarButton(
                  icon: Icons.data_object,
                  tooltip: 'Inline Code',
                  onPressed: () => _insertMarkdown('`', '`'),
                ),
                _ToolbarButton(
                  icon: Icons.link,
                  tooltip: 'Link',
                  onPressed: () => _insertMarkdown('[', '](url)'),
                ),
              ],
            ),
          ),
        // Editor body with line numbers.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers.
              Container(
                width: 48,
                padding: const EdgeInsets.only(top: 12, right: 8),
                color: CodeOpsColors.surfaceVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    lineCount,
                    (i) => Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Text field.
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.tab &&
                        !widget.readOnly) {
                      final selection = _controller.selection;
                      final text = _controller.text;
                      _controller.text = text.replaceRange(
                          selection.start, selection.end, '  ');
                      _controller.selection = TextSelection.collapsed(
                        offset: selection.start + 2,
                      );
                      _onTextChanged(_controller.text);
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    readOnly: widget.readOnly,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Write your persona instructions in Markdown...',
                      hintStyle: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Word / character count.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            border: Border(
              top: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$_wordCount words',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$_charCount characters',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar button
// ---------------------------------------------------------------------------

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      color: CodeOpsColors.textSecondary,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
    );
  }
}
