/// Admin system settings management tab.
///
/// Displays a list of key-value system settings with inline editing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/health_snapshot.dart';
import '../../providers/admin_providers.dart';
import '../../theme/colors.dart';

/// Displays and manages system-level settings.
class SettingsManagementTab extends ConsumerWidget {
  /// Creates a [SettingsManagementTab].
  const SettingsManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(systemSettingsProvider);

    return settingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Text(
        'Failed to load settings: $e',
        style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
      ),
      data: (settings) {
        if (settings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No system settings found.',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
              ),
            ),
          );
        }

        return Column(
          children: settings
              .map((s) => _SettingRow(setting: s))
              .toList(),
        );
      },
    );
  }
}

class _SettingRow extends ConsumerStatefulWidget {
  final SystemSetting setting;

  const _SettingRow({required this.setting});

  @override
  ConsumerState<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends ConsumerState<_SettingRow> {
  bool _isEditing = false;
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.setting.value);
  }

  @override
  void didUpdateWidget(_SettingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setting.value != widget.setting.value && !_isEditing) {
      _controller.text = widget.setting.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final adminApi = ref.read(adminApiProvider);
      await adminApi.updateSetting(
        key: widget.setting.key,
        value: _controller.text,
      );
      ref.invalidate(systemSettingsProvider);
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.setting.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (widget.setting.updatedBy != null)
                Text(
                  'by ${widget.setting.updatedBy}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              if (widget.setting.updatedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('M/d/yy HH:mm').format(widget.setting.updatedAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(isDense: true),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    _controller.text = widget.setting.value;
                    setState(() => _isEditing = false);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            )
          else
            GestureDetector(
              onDoubleTap: () => setState(() => _isEditing = true),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.setting.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 14),
                    color: CodeOpsColors.textTertiary,
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
