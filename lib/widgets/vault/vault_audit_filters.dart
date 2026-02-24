/// Enhanced filter bar for the Vault audit log page.
///
/// Provides operation, resource type, and success/failure dropdowns,
/// text fields for user ID, path, and resource ID, date range pickers
/// with quick-range chips (1h, 6h, 24h, 7d, 30d), and Apply / Clear
/// buttons. All filter state is managed via Riverpod providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart' as du;
import 'vault_audit_table.dart';

/// A comprehensive filter bar for the Vault audit log.
///
/// Renders three rows:
/// 1. Dropdown filters (operation, resource type, success).
/// 2. Text filters (user ID, path, resource ID).
/// 3. Time range pickers, quick-range chips, Apply and Clear buttons.
class VaultAuditFilters extends ConsumerStatefulWidget {
  /// Creates a [VaultAuditFilters].
  const VaultAuditFilters({super.key});

  @override
  ConsumerState<VaultAuditFilters> createState() => _VaultAuditFiltersState();
}

class _VaultAuditFiltersState extends ConsumerState<VaultAuditFilters> {
  late TextEditingController _userIdCtrl;
  late TextEditingController _pathCtrl;
  late TextEditingController _resourceIdCtrl;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _userIdCtrl = TextEditingController(
      text: ref.read(vaultAuditUserIdFilterProvider),
    );
    _pathCtrl = TextEditingController(
      text: ref.read(vaultAuditPathFilterProvider),
    );
    _resourceIdCtrl = TextEditingController(
      text: ref.read(vaultAuditResourceIdFilterProvider),
    );
    _startTime = ref.read(vaultAuditStartTimeProvider);
    _endTime = ref.read(vaultAuditEndTimeProvider);
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _pathCtrl.dispose();
    _resourceIdCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(vaultAuditUserIdFilterProvider.notifier).state =
        _userIdCtrl.text.trim();
    ref.read(vaultAuditPathFilterProvider.notifier).state =
        _pathCtrl.text.trim();
    ref.read(vaultAuditResourceIdFilterProvider.notifier).state =
        _resourceIdCtrl.text.trim();
    ref.read(vaultAuditStartTimeProvider.notifier).state = _startTime;
    ref.read(vaultAuditEndTimeProvider.notifier).state = _endTime;
    ref.read(vaultAuditPageProvider.notifier).state = 0;
  }

  void _clear() {
    ref.read(vaultAuditOperationFilterProvider.notifier).state = '';
    ref.read(vaultAuditResourceTypeFilterProvider.notifier).state = '';
    ref.read(vaultAuditSuccessOnlyProvider.notifier).state = null;
    ref.read(vaultAuditUserIdFilterProvider.notifier).state = '';
    ref.read(vaultAuditPathFilterProvider.notifier).state = '';
    ref.read(vaultAuditResourceIdFilterProvider.notifier).state = '';
    ref.read(vaultAuditStartTimeProvider.notifier).state = null;
    ref.read(vaultAuditEndTimeProvider.notifier).state = null;
    ref.read(vaultAuditPageProvider.notifier).state = 0;
    _userIdCtrl.clear();
    _pathCtrl.clear();
    _resourceIdCtrl.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
    });
  }

  void _setQuickRange(Duration duration) {
    setState(() {
      _endTime = DateTime.now();
      _startTime = _endTime!.subtract(duration);
    });
    _apply();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startTime : _endTime) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;

    final dt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    setState(() {
      if (isStart) {
        _startTime = dt;
      } else {
        _endTime = dt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final operationFilter = ref.watch(vaultAuditOperationFilterProvider);
    final resourceFilter = ref.watch(vaultAuditResourceTypeFilterProvider);
    final successFilter = ref.watch(vaultAuditSuccessOnlyProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dropdown filters
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildDropdown<String>(
                width: 180,
                value: operationFilter.isEmpty ? null : operationFilter,
                hint: 'Operation',
                items: [
                  const DropdownMenuItem(value: '', child: Text('All Operations')),
                  ...vaultAuditOperations.map(
                    (op) => DropdownMenuItem(
                      value: op,
                      child: Text(op, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (v) {
                  ref.read(vaultAuditOperationFilterProvider.notifier).state =
                      v ?? '';
                  ref.read(vaultAuditPageProvider.notifier).state = 0;
                },
              ),
              _buildDropdown<String>(
                width: 160,
                value: resourceFilter.isEmpty ? null : resourceFilter,
                hint: 'Resource',
                items: [
                  const DropdownMenuItem(value: '', child: Text('All Resources')),
                  ...vaultAuditResourceTypes.map(
                    (rt) => DropdownMenuItem(
                      value: rt,
                      child: Text(rt, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (v) {
                  ref
                      .read(vaultAuditResourceTypeFilterProvider.notifier)
                      .state = v ?? '';
                  ref.read(vaultAuditPageProvider.notifier).state = 0;
                },
              ),
              _buildDropdown<bool?>(
                width: 150,
                value: successFilter,
                hint: 'Status',
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('Success Only')),
                  DropdownMenuItem(value: false, child: Text('Failures Only')),
                ],
                onChanged: (v) {
                  ref.read(vaultAuditSuccessOnlyProvider.notifier).state = v;
                  ref.read(vaultAuditPageProvider.notifier).state = 0;
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Text filters
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildTextField(
                controller: _userIdCtrl,
                hint: 'User ID',
                width: 180,
              ),
              _buildTextField(
                controller: _pathCtrl,
                hint: 'Path',
                width: 220,
              ),
              _buildTextField(
                controller: _resourceIdCtrl,
                hint: 'Resource ID',
                width: 180,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Time range + quick-range chips + Apply / Clear
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Start time picker
              _DateChip(
                label: _startTime != null
                    ? du.formatDateTime(_startTime)
                    : 'Start Time',
                icon: Icons.schedule,
                onTap: () => _pickDate(isStart: true),
              ),
              const Text('\u2014',
                  style: TextStyle(color: CodeOpsColors.textTertiary)),
              // End time picker
              _DateChip(
                label: _endTime != null
                    ? du.formatDateTime(_endTime)
                    : 'End Time',
                icon: Icons.schedule,
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(width: 4),
              // Quick-range chips
              _QuickRangeChip(
                label: '1h',
                onTap: () => _setQuickRange(const Duration(hours: 1)),
              ),
              _QuickRangeChip(
                label: '6h',
                onTap: () => _setQuickRange(const Duration(hours: 6)),
              ),
              _QuickRangeChip(
                label: '24h',
                onTap: () => _setQuickRange(const Duration(hours: 24)),
              ),
              _QuickRangeChip(
                label: '7d',
                onTap: () => _setQuickRange(const Duration(days: 7)),
              ),
              _QuickRangeChip(
                label: '30d',
                onTap: () => _setQuickRange(const Duration(days: 30)),
              ),
              const SizedBox(width: 8),
              // Apply / Clear
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Apply'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              OutlinedButton(
                onPressed: _clear,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required double width,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        hint: Text(hint, style: const TextStyle(fontSize: 13)),
        dropdownColor: CodeOpsColors.surface,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textTertiary,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: CodeOpsColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: CodeOpsColors.border),
          ),
        ),
        onSubmitted: (_) => _apply(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: CodeOpsColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickRangeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: CodeOpsColors.border),
    );
  }
}
