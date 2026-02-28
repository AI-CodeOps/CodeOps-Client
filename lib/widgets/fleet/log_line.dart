/// A single log entry line for the container log viewer.
///
/// Colors the text based on the log stream: stdout uses the default
/// text color, stderr uses error red. Timestamps are shown in a
/// subdued tertiary style.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// Renders a single container log line with stream-aware coloring.
class LogLine extends StatelessWidget {
  /// The log content text.
  final String content;

  /// The stream name ('stdout' or 'stderr').
  final String? stream;

  /// The timestamp of the log entry.
  final DateTime? timestamp;

  /// Creates a [LogLine].
  const LogLine({
    super.key,
    required this.content,
    this.stream,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isStderr = stream == 'stderr';
    final textColor =
        isStderr ? CodeOpsColors.error : CodeOpsColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatTimestamp(timestamp!),
                style: CodeOpsTypography.code.copyWith(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: Text(
              content,
              style: CodeOpsTypography.code.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a timestamp as HH:mm:ss.SSS for compact log display.
  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
