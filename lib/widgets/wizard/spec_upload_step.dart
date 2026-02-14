/// Specification file upload step for compliance wizard mode.
///
/// Provides drag-and-drop zone (desktop_drop), file picker button,
/// and file list with remove capability. Enforces file size limit
/// and accepted content types. Validation: at least one file required.
library;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/wizard_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Specification upload step for the wizard flow.
class SpecUploadStep extends StatefulWidget {
  /// The list of uploaded spec files.
  final List<SpecFile> files;

  /// Called when files are added.
  final ValueChanged<List<SpecFile>> onFilesAdded;

  /// Called when a file is removed.
  final ValueChanged<int> onFileRemoved;

  /// Creates a [SpecUploadStep].
  const SpecUploadStep({
    super.key,
    required this.files,
    required this.onFilesAdded,
    required this.onFileRemoved,
  });

  @override
  State<SpecUploadStep> createState() => _SpecUploadStepState();
}

class _SpecUploadStepState extends State<SpecUploadStep> {
  bool _isDragging = false;

  static const _acceptedExtensions = [
    'md', 'txt', 'yaml', 'yml', 'json', 'pdf', 'png', 'jpg', 'jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Specifications',
          style: TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add specification files for compliance checking. '
          'Accepted: Markdown, YAML, JSON, PDF, images. Max 50 MB each.',
          style: TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Drop zone
        DropTarget(
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          onDragDone: (details) {
            setState(() => _isDragging = false);
            _handleDroppedFiles(details);
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isDragging
                  ? CodeOpsColors.primary.withValues(alpha: 0.08)
                  : CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDragging
                    ? CodeOpsColors.primary
                    : CodeOpsColors.border,
                style: BorderStyle.solid,
                width: _isDragging ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: _isDragging
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  _isDragging
                      ? 'Drop files here'
                      : 'Drag & drop files here',
                  style: TextStyle(
                    color: _isDragging
                        ? CodeOpsColors.primary
                        : CodeOpsColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _pickFiles,
                  child: const Text('or browse files'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // File list
        if (widget.files.isNotEmpty) ...[
          Text(
            '${widget.files.length} file(s) attached',
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: widget.files.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final file = widget.files[index];
                return _FileTile(
                  file: file,
                  onRemove: () => widget.onFileRemoved(index),
                );
              },
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text(
                'No files uploaded yet',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _acceptedExtensions,
    );

    if (result != null) {
      final specs = <SpecFile>[];
      for (final file in result.files) {
        if (file.path != null &&
            file.size <= AppConstants.maxSpecFileSizeBytes) {
          specs.add(SpecFile(
            name: file.name,
            path: file.path!,
            sizeBytes: file.size,
            contentType: _contentType(file.extension ?? ''),
          ));
        }
      }
      if (specs.isNotEmpty) {
        widget.onFilesAdded(specs);
      }
    }
  }

  void _handleDroppedFiles(DropDoneDetails details) {
    final specs = <SpecFile>[];
    for (final xfile in details.files) {
      final ext = xfile.name.split('.').last.toLowerCase();
      if (_acceptedExtensions.contains(ext)) {
        specs.add(SpecFile(
          name: xfile.name,
          path: xfile.path,
          sizeBytes: 0, // Size not available from XFile directly.
          contentType: _contentType(ext),
        ));
      }
    }
    if (specs.isNotEmpty) {
      widget.onFilesAdded(specs);
    }
  }

  String _contentType(String ext) => switch (ext.toLowerCase()) {
        'md' => 'text/markdown',
        'txt' => 'text/plain',
        'yaml' || 'yml' => 'text/yaml',
        'json' => 'application/json',
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => 'application/octet-stream',
      };
}

class _FileTile extends StatelessWidget {
  final SpecFile file;
  final VoidCallback onRemove;

  const _FileTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          Icon(_fileIcon(file.contentType),
              size: 18, color: CodeOpsColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (file.sizeBytes > 0)
            Text(
              _formatSize(file.sizeBytes),
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 10,
              ),
            ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 16, color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String contentType) {
    if (contentType.startsWith('image/')) return Icons.image;
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('yaml') || contentType.contains('json')) {
      return Icons.data_object;
    }
    return Icons.description;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
