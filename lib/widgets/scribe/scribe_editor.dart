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

  /// Callback fired on Ctrl+S (Cmd+S on macOS).
  ///
  /// Receives the current editor content as its argument.
  final ValueChanged<String>? onSaved;

  /// Whether the editor is read-only (no editing allowed).
  /// When `true`, [onChanged] is ignored.
  final bool readOnly;

  /// Whether to show line numbers. Defaults to `true`.
  final bool showLineNumbers;

  /// Whether to show code folding indicators in the gutter.
  /// Defaults to `true`.
  final bool showCodeFolding;

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

  /// Whether to auto-focus the editor when mounted. Defaults to `false`.
  final bool autofocus;

  /// Minimum height constraint in logical pixels.
  ///
  /// When `null`, the editor has no minimum height constraint.
  final double? minHeight;

  /// Maximum height constraint in logical pixels.
  ///
  /// When `null`, the editor fills available space.
  final double? maxHeight;

  /// Whether to show the minimap. Defaults to `false`.
  ///
  /// Note: re_editor does not natively support minimaps. This parameter
  /// is reserved for future use and is currently a no-op.
  final bool showMinimap;

  /// Override font family for the editor. When `null`, uses the theme
  /// default (`JetBrains Mono`).
  final String? fontFamily;

  /// Editor theme mode. `'dark'` uses [ScribeTheme.dark], `'light'` uses
  /// [ScribeTheme.light]. Defaults to `'dark'`.
  final String themeMode;

  /// Whether to highlight the line containing the cursor.
  /// Defaults to `true`.
  final bool highlightActiveLine;

  /// Whether to highlight matching brackets when cursor is adjacent.
  /// Defaults to `true`.
  ///
  /// Note: Bracket matching is handled by re_editor's syntax engine.
  /// This parameter controls whether the match highlight color is
  /// applied.
  final bool showBracketMatching;

  /// Whether to auto-insert closing brackets: `(`, `[`, `{`.
  /// Defaults to `true`.
  final bool autoCloseBrackets;

  /// Whether to auto-insert closing quotes: `'`, `"`, `` ` ``.
  /// Defaults to `true`.
  final bool autoCloseQuotes;

  /// Whether to show vertical indent guide lines.
  /// Defaults to `true`.
  ///
  /// Note: Indent guides are rendered via re_editor's chunk indicator
  /// color. Full indent guide rendering depends on re_editor support.
  final bool showIndentGuides;

  /// Optional placeholder text shown when content is empty.
  final String? placeholder;

  /// Optional controller for programmatic access to editor state
  /// (cursor position, selection, scroll position, undo/redo).
  final ScribeEditorController? controller;

  /// Optional focus node for keyboard focus management.
  final FocusNode? focusNode;

  /// Called when the cursor position changes (line and column, 0-based).
  final void Function(int line, int column)? onCursorChanged;

  /// Called when the selection changes (char count and line count).
  ///
  /// Reports 0 for both when the cursor is collapsed (no selection).
  final void Function(int chars, int lines)? onSelectionChanged;

  /// Creates a [ScribeEditor].
  const ScribeEditor({
    super.key,
    this.content = '',
    this.language = 'plaintext',
    this.onChanged,
    this.onSaved,
    this.readOnly = false,
    this.showLineNumbers = true,
    this.showCodeFolding = true,
    this.fontSize = 14.0,
    this.tabSize = 2,
    this.insertSpaces = true,
    this.wordWrap = false,
    this.autofocus = false,
    this.minHeight,
    this.maxHeight,
    this.showMinimap = false,
    this.fontFamily,
    this.themeMode = 'dark',
    this.highlightActiveLine = true,
    this.showBracketMatching = true,
    this.autoCloseBrackets = true,
    this.autoCloseQuotes = true,
    this.showIndentGuides = true,
    this.placeholder,
    this.controller,
    this.focusNode,
    this.onCursorChanged,
    this.onSelectionChanged,
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
  FocusNode? _ownedFocusNode;
  int _lastCursorLine = -1;
  int _lastCursorColumn = -1;
  int _lastSelChars = -1;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _initController();
    _buildHighlightTheme();
    _bindFocusNode();
    _internalController.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant ScribeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller changed.
    if (widget.controller != oldWidget.controller) {
      _internalController.removeListener(_onSelectionChanged);
      _disposeOwnedController();
      _initController();
      _bindFocusNode();
      _internalController.addListener(_onSelectionChanged);
    }
    // Content changed externally (only applies when no external controller).
    else if (widget.controller == null && widget.content != oldWidget.content) {
      _internalController.text = widget.content;
    }

    // Language or theme changed — rebuild highlight theme.
    if (widget.language != oldWidget.language ||
        widget.themeMode != oldWidget.themeMode) {
      _lastLanguage = null; // Force rebuild.
      _buildHighlightTheme();
    }

    // Focus node changed — rebind.
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocusNode();
    }
  }

  @override
  void dispose() {
    _internalController.removeListener(_onSelectionChanged);
    _disposeOwnedController();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    // Defer to avoid setState-during-build when the controller fires
    // during CodeEditor.initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final sel = _internalController.selection;

      // Report cursor position.
      final line = sel.extentIndex;
      final column = sel.extentOffset;
      if (line != _lastCursorLine || column != _lastCursorColumn) {
        _lastCursorLine = line;
        _lastCursorColumn = column;
        widget.onCursorChanged?.call(line, column);
      }

      // Report selection info.
      if (sel.baseIndex == sel.extentIndex &&
          sel.baseOffset == sel.extentOffset) {
        if (_lastSelChars != 0) {
          _lastSelChars = 0;
          widget.onSelectionChanged?.call(0, 0);
        }
      } else {
        final text = _internalController.selectedText;
        final chars = text.length;
        if (chars != _lastSelChars) {
          _lastSelChars = chars;
          final lines = '\n'.allMatches(text).length + 1;
          widget.onSelectionChanged?.call(chars, lines);
        }
      }
    });
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

  void _bindFocusNode() {
    widget.controller?.focusNode = _effectiveFocusNode;
  }

  /// Returns the active [ScribeThemeData] based on [widget.themeMode].
  ScribeThemeData _resolveTheme() {
    return widget.themeMode == 'light'
        ? ScribeTheme.light()
        : ScribeTheme.dark();
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

    final themeData = _resolveTheme();
    _highlightTheme = CodeHighlightTheme(
      languages: <String, CodeHighlightThemeMode>{
        modeKey: CodeHighlightThemeMode(mode: mode),
      },
      theme: themeData.toHighlightThemeMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _resolveTheme();
    final effectiveFontFamily = widget.fontFamily ?? themeData.fontFamily;
    final autoComplete = widget.autoCloseBrackets && widget.autoCloseQuotes;

    Widget editor = CodeEditor(
      controller: _internalController,
      readOnly: widget.readOnly,
      wordWrap: widget.wordWrap,
      autofocus: widget.autofocus,
      focusNode: _effectiveFocusNode,
      hint: widget.placeholder,
      autocompleteSymbols: autoComplete,
      shortcutOverrideActions: _buildShortcutOverrides(),
      style: CodeEditorStyle(
        fontSize: widget.fontSize,
        fontFamily: effectiveFontFamily,
        fontFamilyFallback: const ['Fira Code', 'monospace'],
        fontHeight: 1.5,
        backgroundColor: themeData.background,
        textColor: themeData.variable,
        hintTextColor: themeData.comment,
        selectionColor: themeData.selection,
        cursorColor: themeData.cursor,
        cursorLineColor:
            widget.highlightActiveLine ? themeData.lineHighlight : null,
        chunkIndicatorColor:
            widget.showIndentGuides ? themeData.indentGuide : null,
        codeTheme: _highlightTheme,
      ),
      indicatorBuilder: _buildIndicator(themeData),
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
      chunkAnalyzer: widget.showCodeFolding
          ? const DefaultCodeChunkAnalyzer()
          : const NonCodeChunkAnalyzer(),
      padding: const EdgeInsets.all(8),
    );

    // Apply height constraints if specified.
    if (widget.minHeight != null || widget.maxHeight != null) {
      editor = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: widget.minHeight ?? 0,
          maxHeight: widget.maxHeight ?? double.infinity,
        ),
        child: editor,
      );
    }

    return editor;
  }

  /// Builds the gutter indicator (line numbers + fold markers).
  CodeIndicatorBuilder? _buildIndicator(ScribeThemeData themeData) {
    if (!widget.showLineNumbers && !widget.showCodeFolding) {
      return null;
    }

    return (
      BuildContext context,
      CodeLineEditingController editingController,
      CodeChunkController chunkController,
      CodeIndicatorValueNotifier notifier,
    ) {
      return Row(
        children: <Widget>[
          if (widget.showLineNumbers)
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
              textStyle: TextStyle(
                fontFamily: widget.fontFamily ?? themeData.fontFamily,
                fontSize: widget.fontSize - 1,
                color: themeData.gutterText,
              ),
              focusedTextStyle: TextStyle(
                fontFamily: widget.fontFamily ?? themeData.fontFamily,
                fontSize: widget.fontSize - 1,
                color: themeData.cursor,
              ),
            ),
          if (widget.showCodeFolding)
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
        ],
      );
    };
  }

  /// Builds shortcut override actions (e.g., Ctrl+S save handler).
  Map<Type, Action<Intent>>? _buildShortcutOverrides() {
    if (widget.onSaved == null) return null;

    return <Type, Action<Intent>>{
      CodeShortcutSaveIntent:
          CallbackAction<CodeShortcutSaveIntent>(onInvoke: (_) {
        widget.onSaved?.call(_internalController.text);
        return null;
      }),
    };
  }
}
