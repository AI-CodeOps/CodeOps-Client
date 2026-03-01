/// Search bar for filtering the database navigator tree.
///
/// Provides a compact text field with debounced input (300ms delay)
/// and a clear button. Filters schema and object names in the tree.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A compact search bar that debounces text input.
///
/// Fires [onChanged] after a 300ms pause in typing with the current
/// query string. Includes a clear button that resets the filter immediately.
class NavigatorSearchBar extends StatefulWidget {
  /// Callback invoked with the debounced search query.
  final ValueChanged<String> onChanged;

  /// Creates a [NavigatorSearchBar].
  const NavigatorSearchBar({super.key, required this.onChanged});

  @override
  State<NavigatorSearchBar> createState() => _NavigatorSearchBarState();
}

class _NavigatorSearchBarState extends State<NavigatorSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _hasText = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Debounces text input and fires [onChanged] after 300ms.
  void _onChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  /// Clears the search field and fires [onChanged] immediately.
  void _onClear() {
    _controller.clear();
    setState(() => _hasText = false);
    _debounce?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: SizedBox(
        height: 28,
        child: TextField(
          controller: _controller,
          onChanged: _onChanged,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Filter objects...',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
            suffixIcon: _hasText
                ? IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    color: CodeOpsColors.textTertiary,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: _onClear,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 24),
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            filled: true,
            fillColor: CodeOpsColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: CodeOpsColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: CodeOpsColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: CodeOpsColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
