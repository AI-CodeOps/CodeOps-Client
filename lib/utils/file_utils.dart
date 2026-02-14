/// File-related utility functions.
///
/// Provides helpers for formatting file sizes and extracting path components.
library;

import 'package:path/path.dart' as p;

/// Formats a byte count into a human-readable file size string.
///
/// Examples: '1.2 MB', '456 KB', '100 bytes'.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes bytes';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Returns the file extension from a path (including the dot).
///
/// Example: '/foo/bar/MyFile.dart' returns '.dart'.
String getFileExtension(String path) => p.extension(path);

/// Returns the file name (with extension) from a path.
///
/// Example: '/foo/bar/MyFile.dart' returns 'MyFile.dart'.
String getFileName(String path) => p.basename(path);
