/// A status bar displayed at the bottom of the Scribe editor page.
///
/// Shows seven interactive items: language mode picker, cursor position,
/// selection info, indentation indicator, encoding, line ending, and
/// file size. Each item is clickable to open relevant settings or pickers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';
import 'scribe_language.dart';
import 'scribe_language_picker.dart';

/// A status bar for the Scribe editor with seven interactive items.
///
/// Displays (left to right): language mode, then spacer, then cursor
/// position, selection info (if active), indentation, encoding, line
/// ending, and file size.
class ScribeStatusBar extends ConsumerWidget {
  /// Current cursor line (0-based, displayed as 1-based).
  final int cursorLine;

  /// Current cursor column (0-based, displayed as 1-based).
  final int cursorColumn;

  /// Current language identifier.
  final String language;

  /// Callback when user selects a different language.
  final ValueChanged<String> onLanguageChanged;

  /// Number of characters currently selected, or 0 if none.
  final int selectedChars;

  /// Number of lines in the current selection, or 0 if none.
  final int selectedLines;

  /// Whether the editor uses spaces (true) or tabs (false) for
  /// indentation.
  final bool insertSpaces;

  /// The indentation size (tab width in spaces).
  final int tabSize;

  /// Callback when the user changes indentation settings.
  ///
  /// Called with `true` for spaces, `false` for tabs.
  final ValueChanged<bool> onInsertSpacesChanged;

  /// Callback when the user changes the tab size.
  final ValueChanged<int> onTabSizeChanged;

  /// Text encoding for the active tab (e.g., 'utf-8').
  final String encoding;

  /// Callback when the user changes the encoding.
  final ValueChanged<String> onEncodingChanged;

  /// Line ending style for the active tab ('lf' or 'crlf').
  final String lineEnding;

  /// Callback when the user toggles the line ending style.
  final ValueChanged<String> onLineEndingChanged;

  /// Current content of the active tab, used to compute file size.
  final String content;

  /// Creates a [ScribeStatusBar].
  const ScribeStatusBar({
    super.key,
    required this.cursorLine,
    required this.cursorColumn,
    required this.language,
    required this.onLanguageChanged,
    this.selectedChars = 0,
    this.selectedLines = 0,
    required this.insertSpaces,
    required this.tabSize,
    required this.onInsertSpacesChanged,
    required this.onTabSizeChanged,
    required this.encoding,
    required this.onEncodingChanged,
    required this.lineEnding,
    required this.onLineEndingChanged,
    required this.content,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppConstants.scribeStatusBarHeight,
      color: const Color(0xFF1E1F36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 1. Language mode picker.
          _StatusBarButton(
            text: ScribeLanguage.displayName(language),
            tooltip: 'Select language mode',
            onTap: () => _showLanguagePicker(context),
          ),
          const Spacer(),
          // 2. Cursor position.
          _StatusText('Ln ${cursorLine + 1}, Col ${cursorColumn + 1}'),
          // 3. Selection info (shown only when there is a selection).
          if (selectedChars > 0) ...[
            const _StatusDivider(),
            _StatusText(
              selectedLines > 1
                  ? '$selectedChars chars ($selectedLines lines)'
                  : '$selectedChars selected',
            ),
          ],
          const _StatusDivider(),
          // 4. Indentation indicator.
          _StatusBarButton(
            text: insertSpaces ? 'Spaces: $tabSize' : 'Tabs: $tabSize',
            tooltip: 'Change indentation',
            onTap: () => _showIndentationMenu(context),
          ),
          const _StatusDivider(),
          // 5. Encoding.
          _StatusBarButton(
            text: encoding.toUpperCase(),
            tooltip: 'Change encoding',
            onTap: () => _showEncodingMenu(context),
          ),
          const _StatusDivider(),
          // 6. Line ending.
          _StatusBarButton(
            text: lineEnding.toUpperCase(),
            tooltip: 'Change line endings',
            onTap: () => _showLineEndingMenu(context),
          ),
          const _StatusDivider(),
          // 7. File size.
          _StatusText(_formatFileSize(content.length)),
        ],
      ),
    );
  }

  /// Shows the searchable language picker dialog.
  Future<void> _showLanguagePicker(BuildContext context) async {
    final selected = await ScribeLanguagePicker.show(
      context,
      currentLanguage: language,
    );
    if (selected != null) {
      onLanguageChanged(selected);
    }
  }

  /// Shows the indentation settings popup menu.
  void _showIndentationMenu(BuildContext context) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero) & button.size,
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      items: [
        _buildCheckMenuItem(
          'Indent Using Spaces',
          checked: insertSpaces,
          onTap: () => onInsertSpacesChanged(true),
        ),
        _buildCheckMenuItem(
          'Indent Using Tabs',
          checked: !insertSpaces,
          onTap: () => onInsertSpacesChanged(false),
        ),
        const PopupMenuDivider(),
        ...[2, 4, 8].map((size) => _buildCheckMenuItem(
              'Tab Size: $size',
              checked: tabSize == size,
              onTap: () => onTabSizeChanged(size),
            )),
      ],
    );
  }

  /// Shows the encoding popup menu.
  void _showEncodingMenu(BuildContext context) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero) & button.size,
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      items: [
        for (final enc in _supportedEncodings)
          _buildCheckMenuItem(
            enc.toUpperCase(),
            checked: encoding == enc,
            onTap: () => onEncodingChanged(enc),
          ),
      ],
    );
  }

  /// Shows the line ending popup menu.
  void _showLineEndingMenu(BuildContext context) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero) & button.size,
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      items: [
        _buildCheckMenuItem(
          'LF (Unix/macOS)',
          checked: lineEnding == 'lf',
          onTap: () => onLineEndingChanged('lf'),
        ),
        _buildCheckMenuItem(
          'CRLF (Windows)',
          checked: lineEnding == 'crlf',
          onTap: () => onLineEndingChanged('crlf'),
        ),
      ],
    );
  }

  /// Builds a check-marked popup menu item.
  PopupMenuItem<void> _buildCheckMenuItem(
    String label, {
    required bool checked,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<void>(
      height: 32,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: checked
                ? const Icon(Icons.check, size: 14, color: CodeOpsColors.primary)
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: checked
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textPrimary,
              fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a byte count as a human-readable file size string.
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  /// Supported text encodings.
  static const _supportedEncodings = [
    'utf-8',
    'ascii',
    'iso-8859-1',
    'utf-16',
  ];
}

/// A clickable text button in the status bar.
class _StatusBarButton extends StatelessWidget {
  final String text;
  final String tooltip;
  final VoidCallback onTap;

  const _StatusBarButton({
    required this.text,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small text widget used in the status bar.
class _StatusText extends StatelessWidget {
  final String text;

  const _StatusText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: CodeOpsColors.textSecondary,
        ),
      ),
    );
  }
}

/// A subtle vertical divider between status bar sections.
class _StatusDivider extends StatelessWidget {
  const _StatusDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 1,
        height: 14,
        color: CodeOpsColors.border,
      ),
    );
  }
}
