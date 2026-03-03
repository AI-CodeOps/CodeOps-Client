/// Reusable script code editor for Courier.
///
/// Combines a [ScribeEditor] with a clickable snippet sidebar. Used by both
/// the Scripts tab (pre-request / post-response) and the Tests tab.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';
import '../scribe/scribe_editor_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Snippet model
// ─────────────────────────────────────────────────────────────────────────────

/// A code snippet that can be inserted at the cursor position.
class ScriptSnippet {
  /// Display label shown in the sidebar.
  final String label;

  /// Code text inserted when the snippet is clicked.
  final String code;

  /// Creates a [ScriptSnippet].
  const ScriptSnippet({required this.label, required this.code});
}

// ─────────────────────────────────────────────────────────────────────────────
// ScriptEditor
// ─────────────────────────────────────────────────────────────────────────────

/// A code editor with a collapsible snippet sidebar.
///
/// The editor uses [ScribeEditor] with JavaScript syntax highlighting. The
/// snippet sidebar shows categorised snippets that insert code at the cursor
/// position when clicked.
class ScriptEditor extends StatefulWidget {
  /// Initial script content.
  final String content;

  /// Called on every content change.
  final ValueChanged<String>? onChanged;

  /// Snippets displayed in the sidebar.
  final List<ScriptSnippet> snippets;

  /// Optional placeholder text when the editor is empty.
  final String? placeholder;

  /// Creates a [ScriptEditor].
  const ScriptEditor({
    super.key,
    this.content = '',
    this.onChanged,
    this.snippets = const [],
    this.placeholder,
  });

  @override
  State<ScriptEditor> createState() => _ScriptEditorState();
}

class _ScriptEditorState extends State<ScriptEditor> {
  late final ScribeEditorController _controller;
  bool _snippetsExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = ScribeEditorController(
      content: widget.content,
      language: 'javascript',
    );
  }

  @override
  void didUpdateWidget(ScriptEditor old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content &&
        widget.content != _controller.content) {
      _controller.replaceContent(widget.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertSnippet(ScriptSnippet snippet) {
    _controller.insertAtCursor(snippet.code);
    widget.onChanged?.call(_controller.content);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editor.
        Expanded(
          child: ScribeEditor(
            key: const Key('script_code_editor'),
            controller: _controller,
            language: 'javascript',
            onChanged: widget.onChanged,
            showLineNumbers: true,
            placeholder: widget.placeholder,
            fontSize: 13,
          ),
        ),
        // Snippet sidebar.
        if (widget.snippets.isNotEmpty) ...[
          const VerticalDivider(
              width: 1, thickness: 1, color: CodeOpsColors.border),
          _SnippetSidebar(
            key: const Key('snippet_sidebar'),
            snippets: widget.snippets,
            expanded: _snippetsExpanded,
            onToggle: () =>
                setState(() => _snippetsExpanded = !_snippetsExpanded),
            onInsert: _insertSnippet,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SnippetSidebar
// ─────────────────────────────────────────────────────────────────────────────

class _SnippetSidebar extends StatelessWidget {
  final List<ScriptSnippet> snippets;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ScriptSnippet> onInsert;

  const _SnippetSidebar({
    super.key,
    required this.snippets,
    required this.expanded,
    required this.onToggle,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 220 : 32,
      color: CodeOpsColors.surface,
      child: expanded ? _expandedView() : _collapsedView(),
    );
  }

  Widget _collapsedView() {
    return Column(
      children: [
        IconButton(
          key: const Key('snippet_toggle'),
          onPressed: onToggle,
          icon: const Icon(Icons.chevron_left, size: 16),
          color: CodeOpsColors.textSecondary,
          tooltip: 'Show snippets',
        ),
      ],
    );
  }

  Widget _expandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.code, size: 13, color: CodeOpsColors.textSecondary),
              const SizedBox(width: 4),
              const Text(
                'Snippets',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),
              InkWell(
                key: const Key('snippet_toggle'),
                onTap: onToggle,
                child: const Icon(
                    Icons.chevron_right, size: 16,
                    color: CodeOpsColors.textSecondary),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Snippet list.
        Expanded(
          child: ListView.builder(
            key: const Key('snippet_list'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: snippets.length,
            itemBuilder: (_, i) => _SnippetTile(
              snippet: snippets[i],
              onTap: () => onInsert(snippets[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SnippetTile
// ─────────────────────────────────────────────────────────────────────────────

class _SnippetTile extends StatelessWidget {
  final ScriptSnippet snippet;
  final VoidCallback onTap;

  const _SnippetTile({required this.snippet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snippet.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              snippet.code.length > 60
                  ? '${snippet.code.substring(0, 57)}...'
                  : snippet.code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
