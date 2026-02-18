/// Programmatic controller for [ScribeEditor].
///
/// Wraps [CodeLineEditingController] from re_editor to provide a clean,
/// platform-agnostic API for cursor management, text selection, content
/// manipulation, and undo/redo operations.
library;

import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

/// Controller for programmatic interaction with a [ScribeEditor].
///
/// Provides access to cursor position, text selection, scroll position,
/// content manipulation, and undo/redo operations.
///
/// Usage:
/// ```dart
/// final controller = ScribeEditorController(content: 'Hello World');
/// controller.moveCursor(line: 0, column: 5);
/// controller.insertAtCursor(' Beautiful');
/// print(controller.content); // 'Hello Beautiful World'
/// ```
class ScribeEditorController extends ChangeNotifier {
  /// The underlying re_editor controller.
  final CodeLineEditingController _inner;

  /// Whether this controller owns the inner controller and should
  /// dispose it.
  final bool _ownsInner;

  /// Creates a [ScribeEditorController] with optional initial [content].
  ///
  /// The [tabSize] sets the indentation width in spaces (default 2).
  ScribeEditorController({
    String content = '',
    int tabSize = 2,
  })  : _inner = CodeLineEditingController.fromText(
          content,
          CodeLineOptions(indentSize: tabSize),
        ),
        _ownsInner = true {
    _inner.addListener(_onInnerChanged);
  }

  /// Creates a [ScribeEditorController] from an existing
  /// [CodeLineEditingController].
  ///
  /// The caller retains ownership of [inner] and must dispose it
  /// separately.
  ScribeEditorController.fromInner(CodeLineEditingController inner)
      : _inner = inner,
        _ownsInner = false {
    _inner.addListener(_onInnerChanged);
  }

  /// The underlying [CodeLineEditingController] for use by [ScribeEditor].
  CodeLineEditingController get inner => _inner;

  /// The current text content of the editor.
  String get content => _inner.text;

  /// Replaces the entire content via the setter.
  set content(String value) {
    _inner.text = value;
  }

  /// Current cursor position as line and column (both 0-based).
  ///
  /// When there is an active selection, this returns the extent
  /// (caret) position.
  ({int line, int column}) get cursorPosition {
    final sel = _inner.selection;
    return (line: sel.extentIndex, column: sel.extentOffset);
  }

  /// Current text selection range, or `null` if no selection is active
  /// (i.e., the cursor is collapsed).
  ({int startLine, int startColumn, int endLine, int endColumn})?
      get selection {
    final sel = _inner.selection;
    if (sel.baseIndex == sel.extentIndex &&
        sel.baseOffset == sel.extentOffset) {
      return null;
    }
    // Normalize so start <= end.
    final int startLine;
    final int startColumn;
    final int endLine;
    final int endColumn;
    if (sel.baseIndex < sel.extentIndex ||
        (sel.baseIndex == sel.extentIndex &&
            sel.baseOffset <= sel.extentOffset)) {
      startLine = sel.baseIndex;
      startColumn = sel.baseOffset;
      endLine = sel.extentIndex;
      endColumn = sel.extentOffset;
    } else {
      startLine = sel.extentIndex;
      startColumn = sel.extentOffset;
      endLine = sel.baseIndex;
      endColumn = sel.baseOffset;
    }
    return (
      startLine: startLine,
      startColumn: startColumn,
      endLine: endLine,
      endColumn: endColumn,
    );
  }

  /// Moves the cursor to a specific [line] and [column] (both 0-based).
  ///
  /// The [column] defaults to 0 (beginning of line).
  void moveCursor({required int line, int column = 0}) {
    _inner.selection = CodeLineSelection.collapsed(
      index: line,
      offset: column,
    );
  }

  /// Selects a range of text from [startLine]:[startColumn] to
  /// [endLine]:[endColumn].
  void select({
    required int startLine,
    required int startColumn,
    required int endLine,
    required int endColumn,
  }) {
    _inner.selection = CodeLineSelection(
      baseIndex: startLine,
      baseOffset: startColumn,
      extentIndex: endLine,
      extentOffset: endColumn,
    );
  }

  /// Inserts [text] at the current cursor position.
  ///
  /// If there is an active selection, the selected text is replaced.
  void insertAtCursor(String text) {
    _inner.replaceSelection(text);
  }

  /// Replaces the entire content with [newContent].
  ///
  /// Resets the cursor to the beginning of the document.
  void replaceContent(String newContent) {
    _inner.text = newContent;
  }

  /// Returns the currently selected text, or an empty string if no
  /// selection is active.
  String get selectedText => _inner.selectedText;

  /// Undoes the last edit.
  ///
  /// Returns `true` if an undo operation was performed.
  bool undo() {
    if (!_inner.canUndo) return false;
    _inner.undo();
    return true;
  }

  /// Redoes the last undone edit.
  ///
  /// Returns `true` if a redo operation was performed.
  bool redo() {
    if (!_inner.canRedo) return false;
    _inner.redo();
    return true;
  }

  /// Whether an undo operation is available.
  bool get canUndo => _inner.canUndo;

  /// Whether a redo operation is available.
  bool get canRedo => _inner.canRedo;

  /// Total number of lines in the editor.
  int get lineCount => _inner.lineCount;

  void _onInnerChanged() {
    notifyListeners();
  }

  /// Releases all resources held by this controller.
  @override
  void dispose() {
    _inner.removeListener(_onInnerChanged);
    if (_ownsInner) {
      _inner.dispose();
    }
    super.dispose();
  }
}
