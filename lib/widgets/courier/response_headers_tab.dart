/// Response headers tab for Courier.
///
/// Read-only key-value table of response headers, sorted alphabetically.
/// Click a value to copy it to the clipboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResponseHeadersTab
// ─────────────────────────────────────────────────────────────────────────────

/// Displays response headers as a sorted, read-only table.
///
/// Each row shows the header name and value. Clicking a value copies it to
/// the clipboard.
class ResponseHeadersTab extends StatelessWidget {
  /// Response headers map (case-insensitive keys).
  final Map<String, String> headers;

  /// Creates a [ResponseHeadersTab].
  const ResponseHeadersTab({super.key, required this.headers});

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) {
      return const Center(
        child: Text(
          'No response headers',
          key: Key('headers_empty'),
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    final sorted = headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return Column(
      key: const Key('response_headers_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header count.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.surface,
          child: Text(
            '${sorted.length} header${sorted.length == 1 ? '' : 's'}',
            key: const Key('header_count'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Table header row.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.background,
          child: const Row(
            children: [
              SizedBox(
                width: 200,
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Value',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Rows.
        Expanded(
          child: ListView.separated(
            key: const Key('header_list'),
            padding: EdgeInsets.zero,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 1, color: CodeOpsColors.border),
            itemBuilder: (ctx, i) => _HeaderRow(
              name: sorted[i].key,
              value: sorted[i].value,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeaderRow
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  final String name;
  final String value;

  const _HeaderRow({required this.name, required this.value});

  /// Common headers to highlight.
  static const _highlightHeaders = {
    'content-type',
    'cache-control',
    'set-cookie',
    'location',
    'authorization',
    'x-request-id',
    'x-ratelimit-remaining',
  };

  @override
  Widget build(BuildContext context) {
    final isHighlight = _highlightHeaders.contains(name.toLowerCase());

    return InkWell(
      onTap: () => Clipboard.setData(ClipboardData(text: value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight:
                      isHighlight ? FontWeight.w600 : FontWeight.normal,
                  color: isHighlight
                      ? CodeOpsColors.secondary
                      : CodeOpsColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Tooltip(
              message: 'Click to copy',
              child: Icon(Icons.copy,
                  size: 12, color: CodeOpsColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
