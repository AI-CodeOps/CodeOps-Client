/// Dialog for pulling a Docker image.
///
/// Collects an image name and optional tag. Returns a record of
/// `({String imageName, String tag})` on submission, or `null` if cancelled.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A dialog that lets the user specify an image to pull.
///
/// Returns `({String imageName, String tag})` when submitted,
/// or `null` if cancelled.
class PullImageDialog extends StatefulWidget {
  /// Creates a [PullImageDialog].
  const PullImageDialog({super.key});

  /// Shows the dialog and returns the result.
  static Future<({String imageName, String tag})?> show(
      BuildContext context) {
    return showDialog<({String imageName, String tag})>(
      context: context,
      builder: (_) => const PullImageDialog(),
    );
  }

  @override
  State<PullImageDialog> createState() => _PullImageDialogState();
}

class _PullImageDialogState extends State<PullImageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _imageNameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController(text: 'latest');

  @override
  void dispose() {
    _imageNameCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop((
      imageName: _imageNameCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? 'latest' : _tagCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Pull Image'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _imageNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image Name *',
                  hintText: 'e.g. postgres, nginx, redis',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tag',
                  hintText: 'latest',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Pull'),
        ),
      ],
    );
  }
}
