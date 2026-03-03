/// Binary body editor for the Courier request builder.
///
/// Displays a drag-and-drop zone and file picker for selecting a binary file
/// to attach as the request body. Shows file name, size, and a clear button
/// when a file is selected.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BodyBinaryEditor
// ─────────────────────────────────────────────────────────────────────────────

/// A binary file body editor with file picker and drag-and-drop zone.
///
/// Shows an empty drop zone when no file is selected, or file metadata
/// (name, size) with a clear button when a file has been attached.
class BodyBinaryEditor extends StatelessWidget {
  /// The currently selected file name, or empty if no file is selected.
  final String fileName;

  /// The currently selected file size in bytes, or 0 if no file.
  final int fileSize;

  /// Called when a file is selected (via picker or drag-and-drop).
  final ValueChanged<String> onFileSelected;

  /// Called when the user clears the selected file.
  final VoidCallback onClear;

  /// Creates a [BodyBinaryEditor].
  const BodyBinaryEditor({
    super.key,
    required this.fileName,
    this.fileSize = 0,
    required this.onFileSelected,
    required this.onClear,
  });

  /// Formats byte count into human-readable string.
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (fileName.isNotEmpty) {
      return _buildFileInfo();
    }
    return _buildDropZone();
  }

  Widget _buildDropZone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          key: const Key('binary_drop_zone'),
          width: 400,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: CodeOpsColors.border,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
            color: CodeOpsColors.surfaceVariant.withAlpha(128),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: CodeOpsColors.textTertiary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Drop file here or click to browse',
                style: TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Any file type accepted',
                style: TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('binary_select_button'),
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text(
                  'Select File',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  // File picker integration will be wired in execution phase.
                  // Platform file picker (file_picker package) opens here.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          key: const Key('binary_file_info'),
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: CodeOpsColors.border),
            borderRadius: BorderRadius.circular(12),
            color: CodeOpsColors.surfaceVariant.withAlpha(128),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 40,
                color: CodeOpsColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (fileSize > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(fileSize),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('binary_change_button'),
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: const Text(
                      'Change',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.textSecondary,
                      side: const BorderSide(color: CodeOpsColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      // File picker opens to change file.
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('binary_clear_button'),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.error,
                      side: const BorderSide(color: CodeOpsColors.error),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: onClear,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
