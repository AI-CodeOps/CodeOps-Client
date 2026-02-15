/// Markdown preview with optional section validation panel.
///
/// Renders persona content as formatted markdown and optionally
/// validates the presence of required persona sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../theme/colors.dart';

/// A markdown preview panel with optional section validation.
class PersonaPreview extends StatelessWidget {
  /// The markdown content to render.
  final String content;

  /// Whether to show the section validation panel.
  final bool showValidation;

  /// Creates a [PersonaPreview].
  const PersonaPreview({
    super.key,
    required this.content,
    this.showValidation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showValidation) _SectionValidationPanel(content: content),
        Expanded(
          child: content.isEmpty
              ? const Center(
                  child: Text(
                    'Preview will appear here...',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                )
              : Markdown(
                  data: content,
                  selectable: true,
                  padding: const EdgeInsets.all(16),
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    h1: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    h2: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    h3: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    code: TextStyle(
                      color: CodeOpsColors.secondary,
                      backgroundColor:
                          CodeOpsColors.surfaceVariant.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: CodeOpsColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    blockquote: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                    ),
                    horizontalRuleDecoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: CodeOpsColors.border),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section validation panel
// ---------------------------------------------------------------------------

class _SectionValidationPanel extends StatelessWidget {
  final String content;

  const _SectionValidationPanel({required this.content});

  static const _requiredSections = [
    '## Identity',
    '## Focus Areas',
    '## Severity Calibration',
    '## Output Format',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Sections:',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          ..._requiredSections.map((section) {
            final found = content.contains(section);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  found ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: found ? CodeOpsColors.success : CodeOpsColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  section.replaceFirst('## ', ''),
                  style: TextStyle(
                    color: found
                        ? CodeOpsColors.textSecondary
                        : CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
