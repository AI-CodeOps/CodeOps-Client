/// Inline editor for viewing and editing markdown files.
///
/// Supports view mode (rendered markdown) and edit mode (split-pane
/// with live preview). Prompts for unsaved changes on close.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../theme/colors.dart';

/// Callback for saving edited content.
typedef OnSaveCallback = Future<void> Function(
    String content, String fileName, String fileType);

/// An inline panel for viewing and editing markdown content.
///
/// Renders within its parent's constraints (not as a full-screen dialog).
/// Use [onClose] to handle the close action.
class MarkdownEditorPanel extends StatefulWidget {
  /// The display file name.
  final String fileName;

  /// The file type (persona, prompt, context).
  final String fileType;

  /// The initial markdown content.
  final String initialContent;

  /// Called when the user saves changes.
  final OnSaveCallback onSave;

  /// Called when the user closes the editor.
  final VoidCallback onClose;

  /// Creates a [MarkdownEditorPanel].
  const MarkdownEditorPanel({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.initialContent,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<MarkdownEditorPanel> createState() => _MarkdownEditorPanelState();
}

class _MarkdownEditorPanelState extends State<MarkdownEditorPanel> {
  late final TextEditingController _contentController;
  late final TextEditingController _nameController;
  final ScrollController _editorScroll = ScrollController();
  final ScrollController _previewScroll = ScrollController();
  late String _fileType;
  bool _editing = false;
  bool _saving = false;
  bool _dirty = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _nameController = TextEditingController(text: widget.fileName);
    _fileType = widget.fileType;
    _contentController.addListener(_onContentChanged);
    _editorScroll.addListener(_onEditorScrolled);
    _previewScroll.addListener(_onPreviewScrolled);
  }

  void _onContentChanged() {
    if (!_dirty && _contentController.text != widget.initialContent) {
      setState(() => _dirty = true);
    }
  }

  /// Sync preview scroll to match editor scroll position proportionally.
  void _onEditorScrolled() {
    if (_syncing) return;
    _syncScroll(_editorScroll, _previewScroll);
  }

  /// Sync editor scroll to match preview scroll position proportionally.
  void _onPreviewScrolled() {
    if (_syncing) return;
    _syncScroll(_previewScroll, _editorScroll);
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (!source.hasClients || !target.hasClients) return;
    final sourceMax = source.position.maxScrollExtent;
    final targetMax = target.position.maxScrollExtent;
    if (sourceMax <= 0 || targetMax <= 0) return;

    final ratio = source.offset / sourceMax;
    _syncing = true;
    target.jumpTo((ratio * targetMax).clamp(0.0, targetMax));
    _syncing = false;
  }

  @override
  void dispose() {
    _editorScroll.removeListener(_onEditorScrolled);
    _previewScroll.removeListener(_onPreviewScrolled);
    _editorScroll.dispose();
    _previewScroll.dispose();
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _contentController.text,
        _nameController.text,
        _fileType,
      );
      if (mounted) {
        setState(() {
          _dirty = false;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleClose() async {
    if (!_dirty) {
      widget.onClose();
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: CodeOpsColors.error)),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header bar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: CodeOpsColors.surface,
            border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _handleClose,
                tooltip: 'Close',
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'File name',
                  ),
                  onChanged: (_) {
                    if (!_dirty) setState(() => _dirty = true);
                  },
                ),
              ),
              const Spacer(),
              // File type dropdown.
              DropdownButton<String>(
                value: _fileType,
                underline: const SizedBox.shrink(),
                dropdownColor: CodeOpsColors.surface,
                items: const [
                  DropdownMenuItem(
                      value: 'persona', child: Text('Persona')),
                  DropdownMenuItem(
                      value: 'prompt', child: Text('Prompt')),
                  DropdownMenuItem(
                      value: 'context', child: Text('Context')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _fileType = v;
                      _dirty = true;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              if (!_editing)
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => setState(() => _editing = true),
                )
              else
                TextButton.icon(
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  onPressed: () => setState(() => _editing = false),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // Content area.
        Expanded(
          child: _editing ? _buildEditMode() : _buildViewMode(),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Markdown(
      data: _contentController.text,
      padding: const EdgeInsets.all(24),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CodeOpsColors.textPrimary),
        h2: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CodeOpsColors.textPrimary),
        h3: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary),
        p: const TextStyle(
            fontSize: 14, color: CodeOpsColors.textPrimary),
        code: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          backgroundColor: CodeOpsColors.surfaceVariant,
        ),
        codeblockDecoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Row(
      children: [
        // Left: editor.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              scrollController: _editorScroll,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter markdown...',
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: live preview with synchronized scrolling.
        Expanded(
          child: Markdown(
            controller: _previewScroll,
            data: _contentController.text,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
