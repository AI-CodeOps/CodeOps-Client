/// GraphQL body editor for the Courier request builder.
///
/// Provides a two-panel layout with a query editor (left) and variables editor
/// (right). Both panels use [ScribeEditor] for syntax highlighting — GraphQL
/// mode for the query and JSON mode for the variables.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyGraphqlEditor
// ─────────────────────────────────────────────────────────────────────────────

/// A two-panel GraphQL body editor with query and variables panes.
///
/// The query pane supports GraphQL syntax highlighting. The variables pane
/// supports JSON syntax highlighting with beautify.
class BodyGraphqlEditor extends StatefulWidget {
  /// The current GraphQL query string.
  final String query;

  /// The current GraphQL variables JSON string.
  final String variables;

  /// Called when the query content changes.
  final ValueChanged<String> onQueryChanged;

  /// Called when the variables content changes.
  final ValueChanged<String> onVariablesChanged;

  /// Creates a [BodyGraphqlEditor].
  const BodyGraphqlEditor({
    super.key,
    required this.query,
    required this.variables,
    required this.onQueryChanged,
    required this.onVariablesChanged,
  });

  @override
  State<BodyGraphqlEditor> createState() => _BodyGraphqlEditorState();
}

class _BodyGraphqlEditorState extends State<BodyGraphqlEditor> {
  /// Attempts to beautify JSON variables.
  void _beautifyVariables() {
    try {
      final parsed = jsonDecode(widget.variables);
      final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
      widget.onVariablesChanged(pretty);
    } catch (_) {
      // Ignore invalid JSON — user may still be typing.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Query panel.
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Query header.
                    Container(
                      key: const Key('graphql_query_header'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: CodeOpsColors.surfaceVariant,
                      child: const Row(
                        children: [
                          Icon(Icons.code, size: 14,
                              color: CodeOpsColors.textTertiary),
                          SizedBox(width: 6),
                          Text(
                            'Query',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CodeOpsColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: CodeOpsColors.border),
                    // Query editor.
                    Expanded(
                      child: ScribeEditor(
                        key: const Key('graphql_query_editor'),
                        content: widget.query,
                        language: 'graphql',
                        onChanged: widget.onQueryChanged,
                        showLineNumbers: true,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider between panels.
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: CodeOpsColors.border,
              ),
              // Variables panel.
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Variables header.
                    Container(
                      key: const Key('graphql_variables_header'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: CodeOpsColors.surfaceVariant,
                      child: Row(
                        children: [
                          const Icon(Icons.data_object, size: 14,
                              color: CodeOpsColors.textTertiary),
                          const SizedBox(width: 6),
                          const Text(
                            'Variables',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CodeOpsColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            key: const Key('graphql_beautify_vars_button'),
                            onTap: _beautifyVariables,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_fix_high, size: 12,
                                      color: CodeOpsColors.textTertiary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Beautify',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: CodeOpsColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, color: CodeOpsColors.border),
                    // Variables editor.
                    Expanded(
                      child: ScribeEditor(
                        key: const Key('graphql_variables_editor'),
                        content: widget.variables,
                        language: 'json',
                        onChanged: widget.onVariablesChanged,
                        showLineNumbers: true,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
