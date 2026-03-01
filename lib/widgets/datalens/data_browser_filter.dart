/// Collapsible WHERE clause filter input for the data browser.
///
/// Provides a text field for entering SQL WHERE clause conditions (without
/// the "WHERE" keyword), with Apply and Clear buttons.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A collapsible filter bar for the data browser.
///
/// Shows a text input for WHERE clause conditions with Apply and Clear buttons.
/// The filter is applied when the user taps Apply or presses Enter.
class DataBrowserFilter extends StatefulWidget {
  /// The current filter text.
  final String filterText;

  /// Called when the filter is applied.
  final ValueChanged<String> onApply;

  /// Called when the filter is cleared.
  final VoidCallback onClear;

  /// Creates a [DataBrowserFilter].
  const DataBrowserFilter({
    super.key,
    required this.filterText,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<DataBrowserFilter> createState() => _DataBrowserFilterState();
}

class _DataBrowserFilterState extends State<DataBrowserFilter> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.filterText);
  }

  @override
  void didUpdateWidget(DataBrowserFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterText != widget.filterText) {
      _controller.text = widget.filterText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 14,
            color: CodeOpsColors.textTertiary,
          ),
          const SizedBox(width: 6),
          const Text(
            'WHERE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: CodeOpsColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 28,
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: "status = 'ACTIVE' AND created_at > '2025-01-01'",
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: CodeOpsColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: CodeOpsColors.primary, width: 1),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => widget.onApply(_controller.text),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 28,
            child: TextButton(
              onPressed: () => widget.onApply(_controller.text),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: CodeOpsColors.primary,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Apply'),
            ),
          ),
          SizedBox(
            height: 28,
            child: TextButton(
              onPressed: () {
                _controller.clear();
                widget.onClear();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: CodeOpsColors.textSecondary,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}
