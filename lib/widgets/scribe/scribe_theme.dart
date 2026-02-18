/// Theme configuration for [ScribeEditor].
///
/// Integrates with the CodeOps dark theme system and provides syntax
/// highlighting colors inspired by Material Palenight. Both dark and
/// light variants are available.
library;

import 'package:flutter/painting.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Immutable theme data for the ScribeEditor.
///
/// Contains colors for the editor chrome (background, gutter, cursor,
/// selection) and syntax highlighting (keywords, strings, comments, etc.).
///
/// Use [ScribeTheme.dark] or [ScribeTheme.light] to obtain pre-built
/// instances.
class ScribeThemeData {
  /// Background color of the editor content area.
  final Color background;

  /// Background color of the line number gutter.
  final Color gutterBackground;

  /// Text color for line numbers.
  final Color gutterText;

  /// Highlight color for the current line.
  final Color lineHighlight;

  /// Background color for selected text.
  final Color selection;

  /// Color of the blinking cursor.
  final Color cursor;

  /// Highlight color for matching brackets.
  final Color matchingBracket;

  /// Font family for code content.
  final String fontFamily;

  /// Default font size in logical pixels.
  final double defaultFontSize;

  // -----------------------------------------------------------------------
  // Syntax highlighting colors
  // -----------------------------------------------------------------------

  /// Color for language keywords (`if`, `else`, `class`, `import`, etc.).
  final Color keyword;

  /// Color for string literals.
  final Color string;

  /// Color for numeric literals.
  final Color number;

  /// Color for comments.
  final Color comment;

  /// Color for type names and class references.
  final Color type;

  /// Color for function and method names.
  final Color function;

  /// Color for variable names.
  final Color variable;

  /// Color for operators (`+`, `-`, `=`, `=>`, etc.).
  final Color operator;

  /// Color for annotations / decorators (`@override`, `@deprecated`).
  final Color annotation;

  /// Color for constant values and boolean literals.
  final Color constant;

  /// Color for HTML/XML tag names.
  final Color tag;

  /// Color for HTML/XML attribute names.
  final Color attribute;

  /// Creates a [ScribeThemeData] with all required fields.
  const ScribeThemeData({
    required this.background,
    required this.gutterBackground,
    required this.gutterText,
    required this.lineHighlight,
    required this.selection,
    required this.cursor,
    required this.matchingBracket,
    required this.fontFamily,
    required this.defaultFontSize,
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.type,
    required this.function,
    required this.variable,
    required this.operator,
    required this.annotation,
    required this.constant,
    required this.tag,
    required this.attribute,
  });

  /// Converts the syntax colors to a re_highlight compatible theme map.
  ///
  /// The keys correspond to highlight.js CSS class names used by
  /// [re_highlight] for token classification.
  Map<String, TextStyle> toHighlightThemeMap() {
    return <String, TextStyle>{
      'root': TextStyle(color: variable, backgroundColor: background),
      'keyword': TextStyle(color: keyword),
      'doctag': TextStyle(color: keyword),
      'formula': TextStyle(color: keyword),
      'string': TextStyle(color: string),
      'regexp': TextStyle(color: string),
      'addition': TextStyle(color: string),
      'meta-string': TextStyle(color: string),
      'number': TextStyle(color: number),
      'comment': TextStyle(color: comment, fontStyle: FontStyle.italic),
      'quote': TextStyle(color: comment, fontStyle: FontStyle.italic),
      'type': TextStyle(color: type),
      'built_in': TextStyle(color: type),
      'title.class_': TextStyle(color: type),
      'class-title': TextStyle(color: type),
      'title': TextStyle(color: function),
      'title.function_': TextStyle(color: function),
      'symbol': TextStyle(color: function),
      'bullet': TextStyle(color: function),
      'link': TextStyle(color: function),
      'selector-id': TextStyle(color: function),
      'variable': TextStyle(color: variable),
      'template-variable': TextStyle(color: variable),
      'attr': TextStyle(color: attribute),
      'selector-attr': TextStyle(color: attribute),
      'selector-class': TextStyle(color: attribute),
      'selector-pseudo': TextStyle(color: attribute),
      'literal': TextStyle(color: constant),
      'meta': TextStyle(color: annotation),
      'section': TextStyle(color: tag),
      'name': TextStyle(color: tag),
      'selector-tag': TextStyle(color: tag),
      'deletion': TextStyle(color: tag),
      'subst': TextStyle(color: tag),
      'attribute': TextStyle(color: attribute),
      'emphasis': const TextStyle(fontStyle: FontStyle.italic),
      'strong': const TextStyle(fontWeight: FontWeight.bold),
    };
  }
}

/// Factory for creating [ScribeThemeData] instances that integrate with
/// the CodeOps theme system.
///
/// Colors are derived from the app's theme palette:
/// - Editor background: `#1A1B2E` (matches app background)
/// - Gutter background: slightly darker than editor
/// - Cursor: `#00D9FF` (secondary color)
/// - Syntax colors: Material Palenight-inspired, harmonized with the
///   CodeOps dark palette
class ScribeTheme {
  ScribeTheme._();

  /// Dark theme matching the CodeOps dark UI.
  ///
  /// Syntax colors inspired by Material Palenight for readability
  /// against the `#1A1B2E` background.
  static ScribeThemeData dark() {
    return const ScribeThemeData(
      background: CodeOpsColors.background,
      gutterBackground: Color(0xFF161729),
      gutterText: CodeOpsColors.textTertiary,
      lineHighlight: Color(0xFF252849),
      selection: Color(0x406C63FF),
      cursor: CodeOpsColors.secondary,
      matchingBracket: Color(0x5000D9FF),
      fontFamily: CodeOpsTypography.codeFontFamily,
      defaultFontSize: 14.0,
      // Syntax colors — Material Palenight-inspired
      keyword: Color(0xFFC792EA),
      string: Color(0xFFC3E88D),
      number: Color(0xFFF78C6C),
      comment: Color(0xFF546E7A),
      type: Color(0xFFFFCB6B),
      function: Color(0xFF82AAFF),
      variable: CodeOpsColors.textPrimary,
      operator: Color(0xFF89DDFF),
      annotation: Color(0xFFFF5370),
      constant: Color(0xFFF78C6C),
      tag: Color(0xFFF07178),
      attribute: Color(0xFFFFCB6B),
    );
  }

  /// Light theme for future use or user preference.
  ///
  /// Based on a neutral light palette with sufficient contrast for
  /// all syntax token categories.
  static ScribeThemeData light() {
    return const ScribeThemeData(
      background: Color(0xFFFAFAFA),
      gutterBackground: Color(0xFFF0F0F0),
      gutterText: Color(0xFF999999),
      lineHighlight: Color(0xFFEEEEEE),
      selection: Color(0x40295FCC),
      cursor: Color(0xFF295FCC),
      matchingBracket: Color(0x50295FCC),
      fontFamily: CodeOpsTypography.codeFontFamily,
      defaultFontSize: 14.0,
      // Syntax colors — light palette
      keyword: Color(0xFF7C4DFF),
      string: Color(0xFF558B2F),
      number: Color(0xFFF4511E),
      comment: Color(0xFF90A4AE),
      type: Color(0xFFF9A825),
      function: Color(0xFF1565C0),
      variable: Color(0xFF263238),
      operator: Color(0xFF00838F),
      annotation: Color(0xFFD81B60),
      constant: Color(0xFFF4511E),
      tag: Color(0xFFE53935),
      attribute: Color(0xFFF9A825),
    );
  }
}
