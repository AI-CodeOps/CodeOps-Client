/// Date and time formatting utilities.
///
/// Provides human-friendly formatting for [DateTime] and [Duration] values.
library;

import 'package:intl/intl.dart';

/// Formats a [DateTime] as 'MMM d, yyyy h:mm a' (e.g. "Jan 5, 2025 3:30 PM").
///
/// Returns '—' if [dt] is null.
String formatDateTime(DateTime? dt) {
  if (dt == null) return '\u2014';
  return DateFormat('MMM d, yyyy h:mm a').format(dt);
}

/// Formats a [DateTime] as 'MMM d, yyyy' (e.g. "Jan 5, 2025").
///
/// Returns '—' if [dt] is null.
String formatDate(DateTime? dt) {
  if (dt == null) return '\u2014';
  return DateFormat('MMM d, yyyy').format(dt);
}

/// Formats a [DateTime] as a relative time string.
///
/// Returns values like 'just now', '5m ago', '2h ago', 'yesterday',
/// or a date string for older dates. Returns '—' if [dt] is null.
String formatTimeAgo(DateTime? dt) {
  if (dt == null) return '\u2014';

  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dt);
}

/// Formats a [Duration] as a human-readable string.
///
/// Returns values like '1h 23m 45s', '23m 12s', or '45s'.
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);

  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}
