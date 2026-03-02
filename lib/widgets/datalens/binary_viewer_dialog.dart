/// Binary/LOB viewer dialog for the DataLens data grid.
///
/// Displays binary (bytea) column data as a hex dump with ASCII sidebar,
/// size information, and download capability. Opens as a dialog when the
/// user clicks a binary cell.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

/// A dialog for viewing binary/LOB column data.
///
/// Features:
/// - Hex dump display with 16-byte rows
/// - ASCII sidebar showing printable characters
/// - Size information (bytes / KB / MB)
/// - Copy hex string to clipboard
/// - Upload callback for replacing binary data
class BinaryViewerDialog extends StatelessWidget {
  /// The binary data to display.
  final Uint8List data;

  /// Column name for the dialog title.
  final String columnName;

  /// Called when the user uploads replacement data.
  final ValueChanged<Uint8List>? onUpload;

  /// Creates a [BinaryViewerDialog].
  const BinaryViewerDialog({
    super.key,
    required this.data,
    required this.columnName,
    this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      child: SizedBox(
        width: 700,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(context),
            const Divider(height: 1, color: CodeOpsColors.border),
            _buildToolbar(context),
            const Divider(height: 1, color: CodeOpsColors.border),
            Expanded(child: _buildHexDump()),
            const Divider(height: 1, color: CodeOpsColors.border),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  /// Builds the dialog title bar.
  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.memory,
            size: 16,
            color: CodeOpsColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            columnName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: CodeOpsColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BINARY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.warning,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              size: 16,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the toolbar with copy/upload actions.
  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            _formatSize(data.length),
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy Hex',
            onTap: () => _copyHex(context),
          ),
          if (onUpload != null) ...[
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.upload_file,
              label: 'Upload',
              onTap: () {
                // Upload handling would integrate with file picker.
                // For now, this is a placeholder for the callback.
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the hex dump display.
  Widget _buildHexDump() {
    final rowCount = (data.length / 16).ceil();

    return Container(
      color: CodeOpsColors.background,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rowCount,
          itemBuilder: (context, index) => _buildHexRow(index),
        ),
      ),
    );
  }

  /// Builds a single hex dump row (offset + hex bytes + ASCII).
  Widget _buildHexRow(int rowIndex) {
    final offset = rowIndex * 16;
    final end = (offset + 16).clamp(0, data.length);
    final rowBytes = data.sublist(offset, end);

    // Offset column.
    final offsetHex = offset.toRadixString(16).toUpperCase().padLeft(8, '0');

    // Hex bytes.
    final hexParts = <String>[];
    for (var i = 0; i < 16; i++) {
      if (i < rowBytes.length) {
        hexParts.add(rowBytes[i].toRadixString(16).toUpperCase().padLeft(2, '0'));
      } else {
        hexParts.add('  ');
      }
    }
    final hexStr = '${hexParts.sublist(0, 8).join(' ')}  ${hexParts.sublist(8).join(' ')}';

    // ASCII column.
    final asciiStr = rowBytes
        .map((b) => b >= 32 && b <= 126 ? String.fromCharCode(b) : '.')
        .join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          // Offset.
          SizedBox(
            width: 70,
            child: Text(
              offsetHex,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Hex bytes.
          Expanded(
            flex: 3,
            child: Text(
              hexStr,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Vertical separator.
          Container(
            width: 1,
            height: 14,
            color: CodeOpsColors.border,
          ),
          const SizedBox(width: 8),
          // ASCII.
          SizedBox(
            width: 140,
            child: Text(
              asciiStr,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer with close button.
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${data.length} bytes  |  ${(data.length / 16).ceil()} rows',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 12, color: CodeOpsColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Formats a byte count as a human-readable size string.
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Copies the full hex string to clipboard.
  void _copyHex(BuildContext context) {
    final hex = data
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hex copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// A small toolbar button with icon and label.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: CodeOpsColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
