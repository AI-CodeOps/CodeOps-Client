/// Data models for the Scribe editor.
///
/// Contains [ScribeTab] representing an open editor tab and
/// [ScribeSettings] for persistent editor configuration.
library;

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../widgets/scribe/scribe_language.dart';

/// Represents a single open tab in the Scribe editor.
///
/// Each tab holds its content, language mode, cursor position, and
/// dirty state. Tabs are identified by a unique [id] and displayed
/// with their [title] in the tab bar.
class ScribeTab {
  /// Unique identifier for this tab (UUID).
  final String id;

  /// Display title (file name or "Untitled-N").
  final String title;

  /// The full file path if opened from disk, null if new/unsaved.
  final String? filePath;

  /// Current content of the editor.
  final String content;

  /// Language identifier for syntax highlighting (e.g., 'dart', 'sql').
  final String language;

  /// Whether content has been modified since last save.
  final bool isDirty;

  /// Cursor line position (0-based).
  final int cursorLine;

  /// Cursor column position (0-based).
  final int cursorColumn;

  /// Scroll offset for restoring scroll position on tab switch.
  final double scrollOffset;

  /// Text encoding for this tab (e.g., 'utf-8', 'ascii', 'iso-8859-1').
  final String encoding;

  /// Line ending style for this tab ('lf' or 'crlf').
  final String lineEnding;

  /// Timestamp when this tab was created.
  final DateTime createdAt;

  /// Timestamp of last content modification.
  final DateTime lastModifiedAt;

  /// Creates a [ScribeTab] with all fields.
  const ScribeTab({
    required this.id,
    required this.title,
    this.filePath,
    this.content = '',
    this.language = 'plaintext',
    this.isDirty = false,
    this.cursorLine = 0,
    this.cursorColumn = 0,
    this.scrollOffset = 0.0,
    this.encoding = 'utf-8',
    this.lineEnding = 'lf',
    required this.createdAt,
    required this.lastModifiedAt,
  });

  /// Creates a new empty tab with auto-incrementing title.
  factory ScribeTab.untitled(int number) {
    final now = DateTime.now();
    return ScribeTab(
      id: const Uuid().v4(),
      title: 'Untitled-$number',
      content: '',
      language: 'plaintext',
      createdAt: now,
      lastModifiedAt: now,
    );
  }

  /// Creates a tab from an opened file.
  ///
  /// Detects the language from the file extension using
  /// [ScribeLanguage.fromFileName].
  factory ScribeTab.fromFile({
    required String filePath,
    required String content,
  }) {
    final now = DateTime.now();
    final lastSlash = filePath.lastIndexOf('/');
    final fileName =
        lastSlash >= 0 ? filePath.substring(lastSlash + 1) : filePath;
    final language = ScribeLanguage.fromFileName(filePath);
    final lineEnding = content.contains('\r\n') ? 'crlf' : 'lf';
    return ScribeTab(
      id: const Uuid().v4(),
      title: fileName,
      filePath: filePath,
      content: content,
      language: language,
      lineEnding: lineEnding,
      createdAt: now,
      lastModifiedAt: now,
    );
  }

  /// Creates a copy of this tab with the given fields replaced.
  ScribeTab copyWith({
    String? id,
    String? title,
    String? filePath,
    String? content,
    String? language,
    bool? isDirty,
    int? cursorLine,
    int? cursorColumn,
    double? scrollOffset,
    String? encoding,
    String? lineEnding,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
  }) {
    return ScribeTab(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorColumn: cursorColumn ?? this.cursorColumn,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      encoding: encoding ?? this.encoding,
      lineEnding: lineEnding ?? this.lineEnding,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  /// Serializes this tab to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'content': content,
      'language': language,
      'isDirty': isDirty,
      'cursorLine': cursorLine,
      'cursorColumn': cursorColumn,
      'scrollOffset': scrollOffset,
      'encoding': encoding,
      'lineEnding': lineEnding,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
    };
  }

  /// Deserializes a [ScribeTab] from a JSON-compatible map.
  factory ScribeTab.fromJson(Map<String, dynamic> json) {
    return ScribeTab(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String?,
      content: json['content'] as String? ?? '',
      language: json['language'] as String? ?? 'plaintext',
      isDirty: json['isDirty'] as bool? ?? false,
      cursorLine: json['cursorLine'] as int? ?? 0,
      cursorColumn: json['cursorColumn'] as int? ?? 0,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0.0,
      encoding: json['encoding'] as String? ?? 'utf-8',
      lineEnding: json['lineEnding'] as String? ?? 'lf',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScribeTab && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Settings for the Scribe editor that persist across sessions.
///
/// Contains 15 configurable fields covering appearance, editor behavior,
/// and auto-save. All changes are applied instantly and persisted with
/// a 500ms debounce.
class ScribeSettings {
  /// Font size (12.0 - 24.0). Default: 14.0.
  final double fontSize;

  /// Tab size (2, 4, or 8). Default: 2.
  final int tabSize;

  /// Use spaces instead of tabs. Default: true.
  final bool insertSpaces;

  /// Enable word wrap. Default: false.
  final bool wordWrap;

  /// Show line numbers. Default: true.
  final bool showLineNumbers;

  /// Show minimap. Default: false.
  final bool showMinimap;

  /// Theme mode ("dark" or "light"). Default: "dark".
  final String themeMode;

  /// Font family for the editor. Default: "JetBrains Mono".
  final String fontFamily;

  /// Whether auto-save is enabled. Default: false.
  final bool autoSave;

  /// Auto-save interval in seconds (5 - 300). Default: 30.
  final int autoSaveIntervalSeconds;

  /// Whether to render whitespace characters. Default: false.
  final bool showWhitespace;

  /// Whether to highlight matching brackets. Default: true.
  final bool bracketMatching;

  /// Whether to auto-insert closing brackets. Default: true.
  final bool autoCloseBrackets;

  /// Whether to highlight the line containing the cursor. Default: true.
  final bool highlightActiveLine;

  /// Whether to allow scrolling beyond the last line. Default: true.
  final bool scrollBeyondLastLine;

  /// Creates [ScribeSettings] with sensible defaults.
  const ScribeSettings({
    this.fontSize = 14.0,
    this.tabSize = 2,
    this.insertSpaces = true,
    this.wordWrap = false,
    this.showLineNumbers = true,
    this.showMinimap = false,
    this.themeMode = 'dark',
    this.fontFamily = 'JetBrains Mono',
    this.autoSave = false,
    this.autoSaveIntervalSeconds = 30,
    this.showWhitespace = false,
    this.bracketMatching = true,
    this.autoCloseBrackets = true,
    this.highlightActiveLine = true,
    this.scrollBeyondLastLine = true,
  });

  /// Creates a copy of these settings with the given fields replaced.
  ScribeSettings copyWith({
    double? fontSize,
    int? tabSize,
    bool? insertSpaces,
    bool? wordWrap,
    bool? showLineNumbers,
    bool? showMinimap,
    String? themeMode,
    String? fontFamily,
    bool? autoSave,
    int? autoSaveIntervalSeconds,
    bool? showWhitespace,
    bool? bracketMatching,
    bool? autoCloseBrackets,
    bool? highlightActiveLine,
    bool? scrollBeyondLastLine,
  }) {
    return ScribeSettings(
      fontSize: fontSize ?? this.fontSize,
      tabSize: tabSize ?? this.tabSize,
      insertSpaces: insertSpaces ?? this.insertSpaces,
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showMinimap: showMinimap ?? this.showMinimap,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      autoSave: autoSave ?? this.autoSave,
      autoSaveIntervalSeconds:
          autoSaveIntervalSeconds ?? this.autoSaveIntervalSeconds,
      showWhitespace: showWhitespace ?? this.showWhitespace,
      bracketMatching: bracketMatching ?? this.bracketMatching,
      autoCloseBrackets: autoCloseBrackets ?? this.autoCloseBrackets,
      highlightActiveLine: highlightActiveLine ?? this.highlightActiveLine,
      scrollBeyondLastLine: scrollBeyondLastLine ?? this.scrollBeyondLastLine,
    );
  }

  /// Serializes these settings to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'tabSize': tabSize,
      'insertSpaces': insertSpaces,
      'wordWrap': wordWrap,
      'showLineNumbers': showLineNumbers,
      'showMinimap': showMinimap,
      'themeMode': themeMode,
      'fontFamily': fontFamily,
      'autoSave': autoSave,
      'autoSaveIntervalSeconds': autoSaveIntervalSeconds,
      'showWhitespace': showWhitespace,
      'bracketMatching': bracketMatching,
      'autoCloseBrackets': autoCloseBrackets,
      'highlightActiveLine': highlightActiveLine,
      'scrollBeyondLastLine': scrollBeyondLastLine,
    };
  }

  /// Serializes these settings to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes [ScribeSettings] from a JSON-compatible map.
  factory ScribeSettings.fromJson(Map<String, dynamic> json) {
    return ScribeSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      tabSize: json['tabSize'] as int? ?? 2,
      insertSpaces: json['insertSpaces'] as bool? ?? true,
      wordWrap: json['wordWrap'] as bool? ?? false,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      showMinimap: json['showMinimap'] as bool? ?? false,
      themeMode: json['themeMode'] as String? ?? 'dark',
      fontFamily: json['fontFamily'] as String? ?? 'JetBrains Mono',
      autoSave: json['autoSave'] as bool? ?? false,
      autoSaveIntervalSeconds:
          json['autoSaveIntervalSeconds'] as int? ?? 30,
      showWhitespace: json['showWhitespace'] as bool? ?? false,
      bracketMatching: json['bracketMatching'] as bool? ?? true,
      autoCloseBrackets: json['autoCloseBrackets'] as bool? ?? true,
      highlightActiveLine: json['highlightActiveLine'] as bool? ?? true,
      scrollBeyondLastLine: json['scrollBeyondLastLine'] as bool? ?? true,
    );
  }

  /// Deserializes [ScribeSettings] from a JSON string.
  factory ScribeSettings.fromJsonString(String jsonString) {
    return ScribeSettings.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
