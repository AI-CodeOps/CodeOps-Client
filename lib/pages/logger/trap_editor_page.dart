/// Trap editor page for creating and editing log traps.
///
/// Form-based page at `/logger/traps/:id/edit` for configuring
/// trap name, description, type, conditions, level/source filters,
/// active state, and testing against historical log data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/trap_test_results.dart';
import '../../widgets/shared/empty_state.dart';

/// The trap editor page for creating or editing a log trap.
class TrapEditorPage extends ConsumerStatefulWidget {
  /// The trap ID to edit, or `'new'` for creating a new trap.
  final String trapId;

  /// Creates a [TrapEditorPage].
  const TrapEditorPage({super.key, required this.trapId});

  @override
  ConsumerState<TrapEditorPage> createState() => _TrapEditorPageState();
}

class _TrapEditorPageState extends ConsumerState<TrapEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _patternController;
  late TextEditingController _thresholdController;
  late TextEditingController _windowController;

  TrapType _trapType = TrapType.pattern;
  ConditionType _conditionType = ConditionType.keyword;
  LogLevel? _levelFilter;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isTesting = false;
  TrapTestResult? _testResult;

  bool get _isNew => widget.trapId == 'new';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _patternController = TextEditingController();
    _thresholdController = TextEditingController(text: '10');
    _windowController = TextEditingController(text: '300');

    if (!_isNew) {
      _loadTrap();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _patternController.dispose();
    _thresholdController.dispose();
    _windowController.dispose();
    super.dispose();
  }

  /// Loads an existing trap for editing.
  Future<void> _loadTrap() async {
    try {
      final api = ref.read(loggerApiProvider);
      final trap = await api.getLogTrap(widget.trapId);

      setState(() {
        _nameController.text = trap.name;
        _descriptionController.text = trap.description ?? '';
        _trapType = trap.trapType;
        _isActive = trap.isActive;

        if (trap.conditions.isNotEmpty) {
          final cond = trap.conditions.first;
          _conditionType = cond.conditionType;
          _patternController.text = cond.pattern ?? '';
          _thresholdController.text =
              (cond.threshold ?? 10).toString();
          _windowController.text =
              (cond.windowSeconds ?? 300).toString();
          _levelFilter = cond.logLevel;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trap: $e')),
        );
      }
    }
  }

  /// Saves the trap (create or update).
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() => _isSaving = true);

    try {
      final api = ref.read(loggerApiProvider);
      final conditions = [
        CreateTrapConditionRequest(
          conditionType: _conditionType,
          field: 'message',
          pattern: _conditionType == ConditionType.keyword ||
                  _conditionType == ConditionType.regex
              ? _patternController.text
              : null,
          threshold: _conditionType == ConditionType.frequencyThreshold
              ? int.tryParse(_thresholdController.text)
              : null,
          windowSeconds: _conditionType ==
                      ConditionType.frequencyThreshold ||
                  _conditionType == ConditionType.absence
              ? int.tryParse(_windowController.text)
              : null,
          logLevel: _levelFilter,
        ),
      ];

      if (_isNew) {
        await api.createLogTrap(
          teamId,
          name: _nameController.text.trim(),
          trapType: _trapType,
          conditions: conditions,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        await api.updateLogTrap(
          widget.trapId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          trapType: _trapType,
          isActive: _isActive,
          conditions: conditions,
        );
      }

      ref.invalidate(loggerTrapsProvider);
      if (mounted) context.go('/logger/traps');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save trap: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Tests the current trap configuration.
  Future<void> _testTrap() async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() => _isTesting = true);

    try {
      final api = ref.read(loggerApiProvider);
      final conditions = [
        CreateTrapConditionRequest(
          conditionType: _conditionType,
          field: 'message',
          pattern: _conditionType == ConditionType.keyword ||
                  _conditionType == ConditionType.regex
              ? _patternController.text
              : null,
          threshold: _conditionType == ConditionType.frequencyThreshold
              ? int.tryParse(_thresholdController.text)
              : null,
          windowSeconds: _conditionType ==
                      ConditionType.frequencyThreshold ||
                  _conditionType == ConditionType.absence
              ? int.tryParse(_windowController.text)
              : null,
          logLevel: _levelFilter,
        ),
      ];

      final result = await api.testLogTrapDefinition(
        teamId,
        name: _nameController.text.trim().isEmpty
            ? 'Test'
            : _nameController.text.trim(),
        trapType: _trapType,
        conditions: conditions,
      );

      setState(() => _testResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to configure traps.',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicFields(),
                        const SizedBox(height: 16),
                        _buildTrapTypeSection(),
                        const SizedBox(height: 16),
                        _buildConditionSection(),
                        const SizedBox(height: 16),
                        _buildFiltersSection(),
                        const SizedBox(height: 16),
                        _buildActiveToggle(),
                        const SizedBox(height: 16),
                        _buildTestSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the header bar.
  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: () => context.go('/logger/traps'),
          ),
          const SizedBox(width: 4),
          Text(
            _isNew ? 'Create Trap' : 'Edit Trap',
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds name and description fields.
  Widget _buildBasicFields() {
    return _SectionCard(
      title: 'Basic Information',
      children: [
        TextFormField(
          controller: _nameController,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Name is required' : null,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 13,
          ),
          decoration: _inputDecoration('Trap Name'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 13,
          ),
          decoration: _inputDecoration('Description (optional)'),
        ),
      ],
    );
  }

  /// Builds the trap type selector.
  Widget _buildTrapTypeSection() {
    return _SectionCard(
      title: 'Trap Type',
      children: [
        Wrap(
          spacing: 8,
          children: TrapType.values.map((type) {
            final isSelected = _trapType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _trapType = type;
                  // Sync condition type with trap type.
                  _conditionType = switch (type) {
                    TrapType.pattern => ConditionType.keyword,
                    TrapType.frequency =>
                      ConditionType.frequencyThreshold,
                    TrapType.absence => ConditionType.absence,
                  };
                });
              },
              selectedColor: CodeOpsColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.border,
              ),
              backgroundColor: CodeOpsColors.background,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds the condition configuration section.
  Widget _buildConditionSection() {
    return _SectionCard(
      title: 'Condition',
      children: [
        // Condition type (within the trap type).
        if (_trapType == TrapType.pattern) ...[
          Row(
            children: [
              const Text(
                'Match Type:',
                style: TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Keyword'),
                selected: _conditionType == ConditionType.keyword,
                onSelected: (_) => setState(
                    () => _conditionType = ConditionType.keyword),
                selectedColor:
                    CodeOpsColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _conditionType == ConditionType.keyword
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
                backgroundColor: CodeOpsColors.background,
                side: BorderSide(
                  color: _conditionType == ConditionType.keyword
                      ? CodeOpsColors.primary
                      : CodeOpsColors.border,
                ),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Regex'),
                selected: _conditionType == ConditionType.regex,
                onSelected: (_) =>
                    setState(() => _conditionType = ConditionType.regex),
                selectedColor:
                    CodeOpsColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _conditionType == ConditionType.regex
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                  fontSize: 11,
                ),
                backgroundColor: CodeOpsColors.background,
                side: BorderSide(
                  color: _conditionType == ConditionType.regex
                      ? CodeOpsColors.primary
                      : CodeOpsColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _patternController,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            decoration: _inputDecoration(
              _conditionType == ConditionType.regex
                  ? 'Regex Pattern (e.g., Exception.*timeout)'
                  : 'Keyword (e.g., OutOfMemoryError)',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Pattern is required'
                : null,
          ),
        ],

        if (_trapType == TrapType.frequency) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _thresholdController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: _inputDecoration('Threshold Count'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _windowController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration:
                      _inputDecoration('Window (seconds)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Must be a number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Alert when more than ${_thresholdController.text} matches occur within ${_windowController.text} seconds.',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],

        if (_trapType == TrapType.absence) ...[
          TextFormField(
            controller: _windowController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
            ),
            decoration: _inputDecoration('Expected Window (seconds)'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (int.tryParse(v) == null) return 'Must be a number';
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Alert when no matching logs appear within ${_windowController.text} seconds.',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the level filter section.
  Widget _buildFiltersSection() {
    return _SectionCard(
      title: 'Filters',
      children: [
        Row(
          children: [
            const Text(
              'Level Filter:',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: CodeOpsColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CodeOpsColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LogLevel?>(
                  value: _levelFilter,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Levels')),
                    ...LogLevel.values.map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.displayName),
                        )),
                  ],
                  onChanged: (v) => setState(() => _levelFilter = v),
                  dropdownColor: CodeOpsColors.surface,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                  icon: const Icon(
                    Icons.expand_more,
                    size: 14,
                    color: CodeOpsColors.textTertiary,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the active toggle.
  Widget _buildActiveToggle() {
    return _SectionCard(
      title: 'Status',
      children: [
        Row(
          children: [
            const Text(
              'Active',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeThumbColor: CodeOpsColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              _isActive ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: _isActive
                    ? CodeOpsColors.success
                    : CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the test section.
  Widget _buildTestSection() {
    return _SectionCard(
      title: 'Test Trap',
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testTrap,
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.science, size: 14),
              label: Text(_isTesting ? 'Testing...' : 'Test Against Logs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CodeOpsColors.surfaceVariant,
                foregroundColor: CodeOpsColors.textPrimary,
                textStyle: const TextStyle(fontSize: 12),
                minimumSize: const Size(0, 32),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tests against last 24 hours of log data',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 8),
          TrapTestResults(result: _testResult!),
        ],
      ],
    );
  }

  /// Builds the save/cancel action buttons.
  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 13),
            minimumSize: const Size(100, 36),
          ),
          child: Text(_isSaving
              ? 'Saving...'
              : _isNew
                  ? 'Create Trap'
                  : 'Save Changes'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => context.go('/logger/traps'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CodeOpsColors.textSecondary,
            side: const BorderSide(color: CodeOpsColors.border),
            textStyle: const TextStyle(fontSize: 13),
            minimumSize: const Size(80, 36),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Standard input decoration for form fields.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: CodeOpsColors.textTertiary,
        fontSize: 12,
      ),
      filled: true,
      fillColor: CodeOpsColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.error),
      ),
    );
  }
}

/// A styled card section with title and child content.
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
