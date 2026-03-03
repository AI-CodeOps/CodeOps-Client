/// Body tab content for the Courier request builder.
///
/// Renders the body type selector (radio row) and the appropriate content
/// editor based on the selected type: none, form-data, x-www-form-urlencoded,
/// raw (JSON/XML/HTML/Text/YAML), binary, or GraphQL.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';
import 'body_binary_editor.dart';
import 'body_form_data_editor.dart';
import 'key_value_editor.dart';
import 'body_graphql_editor.dart';
import 'body_raw_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Body types shown as top-level radio options.
const _topLevelTypes = [
  BodyType.none,
  BodyType.formData,
  BodyType.xWwwFormUrlEncoded,
];

/// Raw sub-types available in the "raw" dropdown.
const _rawSubTypes = [
  BodyType.rawJson,
  BodyType.rawXml,
  BodyType.rawHtml,
  BodyType.rawText,
  BodyType.rawYaml,
];

/// Maps body types to their auto-generated Content-Type header value.
const contentTypeForBodyType = <BodyType, String>{
  BodyType.none: '',
  BodyType.formData: 'multipart/form-data',
  BodyType.xWwwFormUrlEncoded: 'application/x-www-form-urlencoded',
  BodyType.rawJson: 'application/json',
  BodyType.rawXml: 'application/xml',
  BodyType.rawHtml: 'text/html',
  BodyType.rawText: 'text/plain',
  BodyType.rawYaml: 'application/x-yaml',
  BodyType.binary: 'application/octet-stream',
  BodyType.graphql: 'application/json',
};

// ─────────────────────────────────────────────────────────────────────────────
// BodyTab
// ─────────────────────────────────────────────────────────────────────────────

/// The Body sub-tab in the request builder.
///
/// Shows a radio-button row for body type selection and renders the
/// corresponding editor widget below. The "raw" option expands into a dropdown
/// for selecting JSON, XML, HTML, Text, or YAML.
class BodyTab extends ConsumerWidget {
  /// Available variable names for `{{}}` autocomplete.
  final List<String> variableNames;

  /// Creates a [BodyTab].
  const BodyTab({super.key, this.variableNames = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyType = ref.watch(bodyTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Body type selector row.
        _BodyTypeSelector(
          selected: bodyType,
          onChanged: (type) {
            ref.read(bodyTypeProvider.notifier).state = type;
          },
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Content area.
        Expanded(
          child: _buildContent(ref, bodyType),
        ),
      ],
    );
  }

  Widget _buildContent(WidgetRef ref, BodyType bodyType) {
    switch (bodyType) {
      case BodyType.none:
        return const _NoneBody();

      case BodyType.formData:
        final entries = ref.watch(bodyFormDataProvider);
        return BodyFormDataEditor(
          key: const Key('body_form_data_editor'),
          entries: _toFormDataEntries(entries),
          onChanged: (updated) {
            ref.read(bodyFormDataProvider.notifier).state =
                updated.map((e) => e.toKeyValuePair()).toList();
          },
          allowFiles: true,
          variableNames: variableNames,
        );

      case BodyType.xWwwFormUrlEncoded:
        final entries = ref.watch(bodyFormDataProvider);
        return BodyFormDataEditor(
          key: const Key('body_urlencoded_editor'),
          entries: _toFormDataEntries(entries),
          onChanged: (updated) {
            ref.read(bodyFormDataProvider.notifier).state =
                updated.map((e) => e.toKeyValuePair()).toList();
          },
          allowFiles: false,
          variableNames: variableNames,
        );

      case BodyType.rawJson:
      case BodyType.rawXml:
      case BodyType.rawHtml:
      case BodyType.rawText:
      case BodyType.rawYaml:
        final content = ref.watch(bodyRawContentProvider);
        return BodyRawEditor(
          key: Key('body_raw_editor_${bodyType.name}'),
          content: content,
          bodyType: bodyType,
          onChanged: (v) {
            ref.read(bodyRawContentProvider.notifier).state = v;
          },
          variableNames: variableNames,
        );

      case BodyType.binary:
        final fileName = ref.watch(bodyBinaryFileNameProvider);
        return BodyBinaryEditor(
          key: const Key('body_binary_editor'),
          fileName: fileName,
          onFileSelected: (name) {
            ref.read(bodyBinaryFileNameProvider.notifier).state = name;
          },
          onClear: () {
            ref.read(bodyBinaryFileNameProvider.notifier).state = '';
          },
        );

      case BodyType.graphql:
        final query = ref.watch(bodyGraphqlQueryProvider);
        final variables = ref.watch(bodyGraphqlVariablesProvider);
        return BodyGraphqlEditor(
          key: const Key('body_graphql_editor'),
          query: query,
          variables: variables,
          onQueryChanged: (v) {
            ref.read(bodyGraphqlQueryProvider.notifier).state = v;
          },
          onVariablesChanged: (v) {
            ref.read(bodyGraphqlVariablesProvider.notifier).state = v;
          },
        );
    }
  }

  /// Converts [KeyValuePair] list to [FormDataEntry] list.
  static List<FormDataEntry> _toFormDataEntries(
      List<KeyValuePair> pairs) {
    return pairs
        .map((p) => FormDataEntry(
              id: p.id,
              key: p.key,
              value: p.value,
              description: p.description,
              enabled: p.enabled,
            ))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoneBody
// ─────────────────────────────────────────────────────────────────────────────

/// Placeholder shown when body type is [BodyType.none].
class _NoneBody extends StatelessWidget {
  const _NoneBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('body_none_hint'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.do_not_disturb_alt, size: 32,
              color: CodeOpsColors.textTertiary),
          SizedBox(height: 8),
          Text(
            'This request does not have a body',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BodyTypeSelector
// ─────────────────────────────────────────────────────────────────────────────

/// Radio button row for selecting the body type.
///
/// Shows top-level radio buttons for none, form-data, x-www-form-urlencoded,
/// a "raw" dropdown for sub-types, binary, and GraphQL.
class _BodyTypeSelector extends StatelessWidget {
  final BodyType selected;
  final ValueChanged<BodyType> onChanged;

  const _BodyTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  bool get _isRaw => _rawSubTypes.contains(selected);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('body_type_selector'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: CodeOpsColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Top-level radio buttons.
            for (final type in _topLevelTypes) ...[
              _TypeRadio(
                key: Key('body_type_${type.name}'),
                label: type.displayName,
                selected: selected == type,
                onTap: () => onChanged(type),
              ),
              const SizedBox(width: 4),
            ],
            // Raw dropdown.
            _RawDropdown(
              key: const Key('body_type_raw_dropdown'),
              selectedType: selected,
              isRawSelected: _isRaw,
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            // Binary.
            _TypeRadio(
              key: const Key('body_type_binary'),
              label: 'binary',
              selected: selected == BodyType.binary,
              onTap: () => onChanged(BodyType.binary),
            ),
            const SizedBox(width: 4),
            // GraphQL.
            _TypeRadio(
              key: const Key('body_type_graphql'),
              label: 'GraphQL',
              selected: selected == BodyType.graphql,
              onTap: () => onChanged(BodyType.graphql),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypeRadio
// ─────────────────────────────────────────────────────────────────────────────

/// A single radio-style chip for body type selection.
class _TypeRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeRadio({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? CodeOpsColors.primary.withAlpha(38)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? CodeOpsColors.primary : CodeOpsColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CodeOpsColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RawDropdown
// ─────────────────────────────────────────────────────────────────────────────

/// A combined radio button + dropdown for the "raw" body type options.
class _RawDropdown extends StatelessWidget {
  final BodyType selectedType;
  final bool isRawSelected;
  final ValueChanged<BodyType> onChanged;

  const _RawDropdown({
    super.key,
    required this.selectedType,
    required this.isRawSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isRawSelected
              ? CodeOpsColors.primary.withAlpha(38)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color:
                isRawSelected ? CodeOpsColors.primary : CodeOpsColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRawSelected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isRawSelected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CodeOpsColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              'raw',
              style: TextStyle(
                fontSize: 11,
                color: isRawSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            PopupMenuButton<BodyType>(
              key: const Key('raw_sub_type_menu'),
              tooltip: 'Select raw format',
              color: CodeOpsColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: onChanged,
              itemBuilder: (_) => _rawSubTypes
                  .map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          if (selectedType == type)
                            const Icon(Icons.check,
                                size: 14, color: CodeOpsColors.primary)
                          else
                            const SizedBox(width: 14),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedType == type
                                  ? CodeOpsColors.primary
                                  : CodeOpsColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isRawSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        // Clicking the radio selects JSON as default raw type.
        if (!isRawSelected) {
          onChanged(BodyType.rawJson);
        }
      },
    );
  }
}
