/// A searchable language picker popup for the Scribe status bar.
///
/// Displays a filterable list of all supported languages. The user can
/// type to narrow results and click to select a language mode.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';
import 'scribe_language.dart';

/// A searchable language picker popup.
///
/// Shows a search field and a scrollable list of supported languages.
/// Selecting a language calls [onSelect] and closes the popup.
///
/// Typically shown by calling [ScribeLanguagePicker.show] from a
/// status bar click handler.
class ScribeLanguagePicker extends StatefulWidget {
  /// The currently selected language identifier.
  final String currentLanguage;

  /// Called when the user selects a language from the list.
  final ValueChanged<String> onSelect;

  /// Called when the user dismisses the picker without selecting.
  final VoidCallback onClose;

  /// Creates a [ScribeLanguagePicker].
  const ScribeLanguagePicker({
    super.key,
    required this.currentLanguage,
    required this.onSelect,
    required this.onClose,
  });

  /// Shows the language picker as a dialog positioned above the status bar.
  ///
  /// Returns the selected language identifier, or `null` if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String currentLanguage,
  }) async {
    String? selected;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30, left: 12),
          child: Material(
            color: Colors.transparent,
            child: ScribeLanguagePicker(
              currentLanguage: currentLanguage,
              onSelect: (lang) {
                selected = lang;
                Navigator.of(ctx).pop();
              },
              onClose: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
    return selected;
  }

  @override
  State<ScribeLanguagePicker> createState() => _ScribeLanguagePickerState();
}

class _ScribeLanguagePickerState extends State<ScribeLanguagePicker> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = ScribeLanguage.supportedLanguages;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = ScribeLanguage.supportedLanguages;
      } else {
        final lower = query.toLowerCase();
        _filteredLanguages = ScribeLanguage.supportedLanguages
            .where((lang) =>
                ScribeLanguage.displayName(lang)
                    .toLowerCase()
                    .contains(lower) ||
                lang.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.scribeLanguagePickerWidth,
      height: AppConstants.scribeLanguagePickerHeight,
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search field.
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search languages...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                filled: true,
                fillColor: CodeOpsColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: CodeOpsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: CodeOpsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: CodeOpsColors.primary),
                ),
              ),
            ),
          ),
          // Language list.
          Expanded(
            child: _filteredLanguages.isEmpty
                ? const Center(
                    child: Text(
                      'No matching languages',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 4),
                    itemCount: _filteredLanguages.length,
                    itemExtent: 28,
                    itemBuilder: (context, index) {
                      final lang = _filteredLanguages[index];
                      final isSelected = lang == widget.currentLanguage;
                      return _LanguageItem(
                        language: lang,
                        isSelected: isSelected,
                        onTap: () => widget.onSelect(lang),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single language item in the picker list.
class _LanguageItem extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: CodeOpsColors.primary,
                ),
              ),
            Expanded(
              child: Text(
                ScribeLanguage.displayName(language),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
