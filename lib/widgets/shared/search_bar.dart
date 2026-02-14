/// Debounced search bar with clear button.
///
/// Fires [onChanged] after a configurable debounce delay.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A search text field with timer-based debounce and clear button.
class CodeOpsSearchBar extends StatefulWidget {
  /// Placeholder text shown when the field is empty.
  final String hint;

  /// Called with the current text after the debounce delay.
  final ValueChanged<String> onChanged;

  /// Debounce duration before [onChanged] fires.
  final Duration debounceDuration;

  /// Creates a [CodeOpsSearchBar].
  const CodeOpsSearchBar({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CodeOpsSearchBar> createState() => _CodeOpsSearchBarState();
}

class _CodeOpsSearchBarState extends State<CodeOpsSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      style: const TextStyle(color: CodeOpsColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, color: CodeOpsColors.textTertiary),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: CodeOpsColors.textTertiary,
                onPressed: _onClear,
              )
            : null,
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.primary),
        ),
      ),
    );
  }
}
