/// String manipulation utilities.
///
/// Provides common text transformations and validation helpers.
library;

/// Truncates [s] to [max] characters, appending '...' if truncated.
///
/// Returns the original string if its length is within [max].
String truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}...';
}

/// Returns a pluralized string based on [count].
///
/// Uses [singular] for a count of 1, and [plural] (or '${singular}s')
/// for all other counts.
String pluralize(int count, String singular, [String? plural]) {
  if (count == 1) return '$count $singular';
  return '$count ${plural ?? '${singular}s'}';
}

/// Converts a camelCase string to Title Case.
///
/// Example: 'codeQuality' becomes 'Code Quality'.
String camelToTitle(String s) {
  if (s.isEmpty) return s;
  final result = s.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (m) => ' ${m.group(0)}',
  );
  return result[0].toUpperCase() + result.substring(1);
}

/// Converts a SCREAMING_SNAKE_CASE string to Title Case.
///
/// Example: 'CODE_QUALITY' becomes 'Code Quality'.
String snakeToTitle(String s) {
  if (s.isEmpty) return s;
  return s
      .split('_')
      .map((w) =>
          w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

/// Returns `true` if [email] matches a basic email format.
bool isValidEmail(String email) => _emailRegex.hasMatch(email);
