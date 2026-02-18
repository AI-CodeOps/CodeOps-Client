/// Core reusable code editor widget for the CodeOps platform.
///
/// Wraps [re_editor]'s [CodeEditor] to provide syntax-highlighted editing
/// with a clean, consistent API. Consumed by every Control Plane UI module:
/// Courier (scripts), DataLens (SQL), Logger (queries), Registry (configs),
/// and Vault (secrets).
///
/// Uses re_editor (^0.8.0) for the editor core and re_highlight for syntax
/// highlighting across 30+ languages. Selected over flutter_code_editor and
/// code_text_field for superior desktop keyboard support, built-in code
/// folding, bracket matching, and comprehensive language coverage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';

import 'scribe_editor_controller.dart';
import 'scribe_language.dart';
import 'scribe_theme.dart';

/// A shared, reusable code editor widget for the CodeOps platform.
///
/// ScribeEditor provides syntax-highlighted code editing with support for
/// 30+ programming languages. It is consumed by every Control Plane UI
/// module: Courier (scripts), DataLens (SQL), Logger (queries), Registry
/// (configs), and Vault (secrets).
///
/// Usage:
/// ```dart
/// ScribeEditor(
///   content: 'SELECT * FROM users;',
///   language: 'sql',
///   onChanged: (value) => setState(() => _sql = value),
/// )
/// ```
class ScribeEditor extends ConsumerStatefulWidget {
  /// Initial content to display in the editor.
  final String content;

  /// Language mode for syntax highlighting (e.g., `'dart'`, `'java'`,
  /// `'sql'`, `'javascript'`, `'json'`, `'yaml'`, `'markdown'`,
  /// `'python'`, `'typescript'`, `'xml'`, `'html'`, `'css'`,
  /// `'dockerfile'`, `'shell'`, `'plaintext'`).
  final String language;

  /// Callback fired on every content change. Null for read-only mode.
  final ValueChanged<String>? onChanged;

  /// Whether the editor is read-only (no editing allowed).
  /// When `true`, [onChanged] is ignored.
  final bool readOnly;

  /// Whether to show line numbers. Defaults to `true`.
  final bool showLineNumbers;

  /// Font size in logical pixels. Defaults to `14.0`.
  /// Valid range: 12.0 to 24.0.
  final double fontSize;

  /// Number of spaces per tab. Defaults to `2`.
  /// Valid values: 2, 4, 8.
  final int tabSize;

  /// Whether to use spaces instead of tab characters. Defaults to `true`.
  final bool insertSpaces;

  /// Whether to enable word wrap. Defaults to `false` (scroll
  /// horizontally).
  final bool wordWrap;

  /// Whether to show the minimap. Defaults to `false`.
  ///
  /// Note: re_editor does not natively support minimaps. This parameter
  /// is reserved for future use and is currently a no-op.
  final bool showMinimap;

  /// Optional placeholder text shown when content is empty.
  final String? placeholder;

  /// Optional controller for programmatic access to editor state
  /// (cursor position, selection, scroll position, undo/redo).
  final ScribeEditorController? controller;

  /// Optional focus node for keyboard focus management.
  final FocusNode? focusNode;

  /// Creates a [ScribeEditor].
  const ScribeEditor({
    super.key,
    this.content = '',
    this.language = 'plaintext',
    this.onChanged,
    this.readOnly = false,
    this.showLineNumbers = true,
    this.fontSize = 14.0,
    this.tabSize = 2,
    this.insertSpaces = true,
    this.wordWrap = false,
    this.showMinimap = false,
    this.placeholder,
    this.controller,
    this.focusNode,
  })  : assert(fontSize >= 12.0 && fontSize <= 24.0),
        assert(tabSize == 2 || tabSize == 4 || tabSize == 8);

  @override
  ConsumerState<ScribeEditor> createState() => _ScribeEditorState();
}

class _ScribeEditorState extends ConsumerState<ScribeEditor> {
  late CodeLineEditingController _internalController;
  bool _ownsController = false;
  CodeHighlightTheme? _highlightTheme;
  String? _lastLanguage;

  @override
  void initState() {
    super.initState();
    _initController();
    _buildHighlightTheme();
  }

  @override
  void didUpdateWidget(covariant ScribeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller changed.
    if (widget.controller != oldWidget.controller) {
      _disposeOwnedController();
      _initController();
    }
    // Content changed externally (only applies when no external controller).
    else if (widget.controller == null && widget.content != oldWidget.content) {
      _internalController.text = widget.content;
    }

    // Language changed — rebuild highlight theme.
    if (widget.language != oldWidget.language) {
      _buildHighlightTheme();
    }
  }

  @override
  void dispose() {
    _disposeOwnedController();
    super.dispose();
  }

  void _initController() {
    if (widget.controller != null) {
      _internalController = widget.controller!.inner;
      _ownsController = false;
    } else {
      _internalController = CodeLineEditingController.fromText(
        widget.content,
        CodeLineOptions(indentSize: widget.tabSize),
      );
      _ownsController = true;
    }
  }

  void _disposeOwnedController() {
    if (_ownsController) {
      _internalController.dispose();
    }
  }

  void _buildHighlightTheme() {
    final modeKey =
        ScribeLanguage.highlightModeKeys[widget.language] ?? 'plaintext';

    if (modeKey == _lastLanguage && _highlightTheme != null) {
      return;
    }
    _lastLanguage = modeKey;

    final Mode? mode = builtinAllLanguages[modeKey];
    if (mode == null) {
      _highlightTheme = null;
      return;
    }

    final themeData = ScribeTheme.dark();
    _highlightTheme = CodeHighlightTheme(
      languages: <String, CodeHighlightThemeMode>{
        modeKey: CodeHighlightThemeMode(mode: mode),
      },
      theme: themeData.toHighlightThemeMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ScribeTheme.dark();

    return CodeEditor(
      controller: _internalController,
      readOnly: widget.readOnly,
      wordWrap: widget.wordWrap,
      focusNode: widget.focusNode,
      hint: widget.placeholder,
      style: CodeEditorStyle(
        fontSize: widget.fontSize,
        fontFamily: themeData.fontFamily,
        fontFamilyFallback: const ['Fira Code', 'monospace'],
        fontHeight: 1.5,
        backgroundColor: themeData.background,
        textColor: themeData.variable,
        hintTextColor: themeData.comment,
        selectionColor: themeData.selection,
        cursorColor: themeData.cursor,
        cursorLineColor: themeData.lineHighlight,
        codeTheme: _highlightTheme,
      ),
      indicatorBuilder: widget.showLineNumbers
          ? (
              BuildContext context,
              CodeLineEditingController editingController,
              CodeChunkController chunkController,
              CodeIndicatorValueNotifier notifier,
            ) {
              return Row(
                children: <Widget>[
                  DefaultCodeLineNumber(
                    controller: editingController,
                    notifier: notifier,
                    textStyle: TextStyle(
                      fontFamily: themeData.fontFamily,
                      fontSize: widget.fontSize - 1,
                      color: themeData.gutterText,
                    ),
                    focusedTextStyle: TextStyle(
                      fontFamily: themeData.fontFamily,
                      fontSize: widget.fontSize - 1,
                      color: themeData.cursor,
                    ),
                  ),
                  DefaultCodeChunkIndicator(
                    width: 20,
                    controller: chunkController,
                    notifier: notifier,
                  ),
                ],
              );
            }
          : null,
      sperator: widget.showLineNumbers
          ? Container(
              width: 1,
              color: themeData.gutterBackground,
            )
          : null,
      onChanged: widget.readOnly
          ? null
          : (CodeLineEditingValue value) {
              widget.onChanged?.call(_internalController.text);
            },
      chunkAnalyzer: const DefaultCodeChunkAnalyzer(),
      padding: const EdgeInsets.all(8),
    );
  }
}
