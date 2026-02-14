/// Markdown rendering widget with syntax highlighting.
///
/// Uses flutter_markdown for rich text and flutter_highlight for code blocks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/colors.dart';

/// Renders markdown content with syntax-highlighted code blocks.
class MarkdownRenderer extends StatelessWidget {
  /// The markdown content to render.
  final String content;

  /// Whether the widget should be scrollable.
  final bool selectable;

  /// Whether to shrink-wrap the content.
  final bool shrinkWrap;

  /// Optional padding around the content.
  final EdgeInsets? padding;

  /// Creates a [MarkdownRenderer].
  const MarkdownRenderer({
    super.key,
    required this.content,
    this.selectable = true,
    this.shrinkWrap = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final styleSheet = MarkdownStyleSheet(
      p: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 13,
        height: 1.6,
      ),
      h1: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      h2: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      h3: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      code: TextStyle(
        color: CodeOpsColors.secondary,
        backgroundColor: CodeOpsColors.surfaceVariant,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      blockquote: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: CodeOpsColors.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      listBullet: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 13,
      ),
      tableHead: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      tableBody: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 12,
      ),
      tableBorder: TableBorder.all(
        color: CodeOpsColors.border,
        width: 1,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CodeOpsColors.divider,
            width: 1,
          ),
        ),
      ),
      a: const TextStyle(
        color: CodeOpsColors.primary,
        decoration: TextDecoration.underline,
      ),
    );

    if (selectable) {
      return Markdown(
        data: content,
        styleSheet: styleSheet,
        padding: padding ?? const EdgeInsets.all(0),
        shrinkWrap: shrinkWrap,
        selectable: true,
        onTapLink: (text, href, title) => _openLink(href),
        builders: {
          'code': _CodeBlockBuilder(),
        },
      );
    }

    return MarkdownBody(
      data: content,
      styleSheet: styleSheet,
      shrinkWrap: shrinkWrap,
      selectable: true,
      onTapLink: (text, href, title) => _openLink(href),
      builders: {
        'code': _CodeBlockBuilder(),
      },
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    // Detect language from class attribute (e.g., "language-dart")
    String? language;
    if (element.attributes.containsKey('class')) {
      final cls = element.attributes['class']!;
      if (cls.startsWith('language-')) {
        language = cls.substring(9);
      }
    }

    // Only apply syntax highlighting for fenced code blocks (multi-line)
    if (textContent.contains('\n')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: HighlightView(
            textContent,
            language: language ?? 'plaintext',
            theme: monokaiSublimeTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return null;
  }
}
