/// SQL text editor widget for the DataLens SQL editor panel.
///
/// Wraps [ScribeEditor] with SQL syntax highlighting, line numbers,
/// keyboard shortcut support (Ctrl+Enter to execute, Ctrl+S to save,
/// Ctrl+Shift+F to format), and a toolbar via [SqlEditorToolbar].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';
import '../scribe/scribe_editor_controller.dart';
import 'sql_editor_toolbar.dart';

/// A SQL text editor for a single editor tab.
///
/// Composes [SqlEditorToolbar] above a [ScribeEditor] configured for SQL
/// syntax highlighting with line numbers and code folding. Supports
/// keyboard shortcuts for execution, saving, and formatting.
class SqlEditorWidget extends StatefulWidget {
  /// Initial SQL content.
  final String content;

  /// Called when the editor content changes.
  final ValueChanged<String>? onContentChanged;

  /// Called when the Execute action is triggered (button or Ctrl+Enter).
  final VoidCallback? onExecute;

  /// Called when the Cancel action is triggered.
  final VoidCallback? onCancel;

  /// Called when the Save action is triggered (button or Ctrl+S).
  final VoidCallback? onSave;

  /// Called when the Explain action is triggered.
  final VoidCallback? onExplain;

  /// Called when the Format action is triggered (button or Ctrl+Shift+F).
  final VoidCallback? onFormat;

  /// Called when the History action is triggered.
  final VoidCallback? onHistory;

  /// Whether a query is currently running.
  final bool isRunning;

  /// Optional external controller for programmatic access.
  final ScribeEditorController? controller;

  /// Creates a [SqlEditorWidget].
  const SqlEditorWidget({
    super.key,
    this.content = '',
    this.onContentChanged,
    this.onExecute,
    this.onCancel,
    this.onSave,
    this.onExplain,
    this.onFormat,
    this.onHistory,
    this.isRunning = false,
    this.controller,
  });

  @override
  State<SqlEditorWidget> createState() => _SqlEditorWidgetState();
}

class _SqlEditorWidgetState extends State<SqlEditorWidget> {
  late ScribeEditorController _controller;
  bool _ownsController = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant SqlEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _disposeOwnedController();
      _initController();
    }
  }

  @override
  void dispose() {
    _disposeOwnedController();
    _focusNode.dispose();
    super.dispose();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = ScribeEditorController(
        content: widget.content,
        language: 'sql',
      );
      _ownsController = true;
    }
  }

  void _disposeOwnedController() {
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        SqlEditorToolbar(
          onExecute: widget.onExecute,
          onCancel: widget.onCancel,
          onSave: widget.onSave,
          onExplain: widget.onExplain,
          onFormat: widget.onFormat,
          onHistory: widget.onHistory,
          isRunning: widget.isRunning,
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Editor with keyboard shortcuts
        Expanded(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(
                LogicalKeyboardKey.enter,
                control: true,
              ): () => widget.onExecute?.call(),
              const SingleActivator(
                LogicalKeyboardKey.keyS,
                control: true,
                shift: true,
              ): () => widget.onFormat?.call(),
            },
            child: Focus(
              focusNode: _focusNode,
              child: ScribeEditor(
                controller: _controller,
                language: 'sql',
                showLineNumbers: true,
                showCodeFolding: true,
                autofocus: true,
                placeholder: 'Enter SQL query...',
                onChanged: widget.onContentChanged,
                onSaved: widget.onSave != null
                    ? (_) => widget.onSave!()
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
