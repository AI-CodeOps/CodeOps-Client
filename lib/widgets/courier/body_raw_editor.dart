/// Raw body editor for the Courier request builder.
///
/// Provides a syntax-highlighted code editor via [ScribeEditor] with a toolbar
/// for beautify, minify, word-wrap toggle, and copy. Supports JSON, XML, HTML,
/// YAML, and plain text modes.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/courier_enums.dart';
import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyRawEditor
// ─────────────────────────────────────────────────────────────────────────────

/// A raw body editor with syntax highlighting, beautify/minify, and word wrap.
///
/// The [bodyType] determines the language mode for syntax highlighting.
/// Supports JSON, XML, HTML, YAML, and plain text.
class BodyRawEditor extends StatefulWidget {
  /// The current raw body content.
  final String content;

  /// The active body type (determines language mode).
  final BodyType bodyType;

  /// Called whenever the content changes.
  final ValueChanged<String> onChanged;

  /// Available variable names for `{{}}` highlighting reference.
  final List<String> variableNames;

  /// Creates a [BodyRawEditor].
  const BodyRawEditor({
    super.key,
    required this.content,
    required this.bodyType,
    required this.onChanged,
    this.variableNames = const [],
  });

  @override
  State<BodyRawEditor> createState() => _BodyRawEditorState();
}

class _BodyRawEditorState extends State<BodyRawEditor> {
  bool _wordWrap = false;

  /// Maps [BodyType] to the ScribeEditor language string.
  static String _languageFor(BodyType type) => switch (type) {
        BodyType.rawJson => 'json',
        BodyType.rawXml => 'xml',
        BodyType.rawHtml => 'html',
        BodyType.rawYaml => 'yaml',
        _ => 'plaintext',
      };

  /// Attempts to beautify content based on body type.
  String? _beautify(String content) {
    if (widget.bodyType == BodyType.rawJson) {
      try {
        final parsed = jsonDecode(content);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {
        return null;
      }
    }
    // XML / HTML / YAML beautification is non-trivial; return null to signal
    // that the operation is not supported for this type.
    return null;
  }

  /// Attempts to minify content based on body type.
  String? _minify(String content) {
    if (widget.bodyType == BodyType.rawJson) {
      try {
        final parsed = jsonDecode(content);
        return jsonEncode(parsed);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _onBeautify() {
    final result = _beautify(widget.content);
    if (result != null) {
      widget.onChanged(result);
    }
  }

  void _onMinify() {
    final result = _minify(widget.content);
    if (result != null) {
      widget.onChanged(result);
    }
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.content));
  }

  @override
  Widget build(BuildContext context) {
    final language = _languageFor(widget.bodyType);
    final canBeautify = widget.bodyType == BodyType.rawJson;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar.
        Container(
          key: const Key('raw_editor_toolbar'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: CodeOpsColors.surfaceVariant,
          child: Row(
            children: [
              // Language label.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.primary.withAlpha(38),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.bodyType.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              // Beautify button.
              if (canBeautify) ...[
                _ToolbarButton(
                  key: const Key('beautify_button'),
                  icon: Icons.auto_fix_high,
                  label: 'Beautify',
                  onPressed: _onBeautify,
                ),
                const SizedBox(width: 4),
                _ToolbarButton(
                  key: const Key('minify_button'),
                  icon: Icons.compress,
                  label: 'Minify',
                  onPressed: _onMinify,
                ),
                const SizedBox(width: 4),
              ],
              // Word wrap toggle.
              _ToolbarButton(
                key: const Key('word_wrap_button'),
                icon: Icons.wrap_text,
                label: 'Wrap',
                isActive: _wordWrap,
                onPressed: () => setState(() => _wordWrap = !_wordWrap),
              ),
              const SizedBox(width: 4),
              // Copy button.
              _ToolbarButton(
                key: const Key('copy_button'),
                icon: Icons.copy,
                label: 'Copy',
                onPressed: _onCopy,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Editor.
        Expanded(
          child: ScribeEditor(
            key: Key('raw_editor_$language'),
            content: widget.content,
            language: language,
            onChanged: widget.onChanged,
            wordWrap: _wordWrap,
            showLineNumbers: true,
            showCodeFolding: true,
            fontSize: 13.0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ToolbarButton
// ─────────────────────────────────────────────────────────────────────────────

/// A compact toolbar button used in the raw editor toolbar.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? CodeOpsColors.primary.withAlpha(38)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
