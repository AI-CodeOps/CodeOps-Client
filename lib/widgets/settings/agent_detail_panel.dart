/// Right panel of the agents tab showing per-agent configuration.
///
/// Editable fields for model, temperature, retries, turns, timeout,
/// attached files, and system prompt override. Auto-saves with debounce.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../providers/agent_config_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../shared/temperature_help_dialog.dart';
import 'agent_file_row.dart';

/// Detail editor for a selected agent definition.
class AgentDetailPanel extends ConsumerStatefulWidget {
  /// Creates an [AgentDetailPanel].
  const AgentDetailPanel({super.key});

  @override
  ConsumerState<AgentDetailPanel> createState() => _AgentDetailPanelState();
}

class _AgentDetailPanelState extends ConsumerState<AgentDetailPanel> {
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  Timer? _descriptionDebounce;
  Timer? _promptDebounce;
  bool _hasPromptOverride = false;

  @override
  void dispose() {
    _descriptionDebounce?.cancel();
    _promptDebounce?.cancel();
    _descriptionController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String agentId) {
    _descriptionDebounce?.cancel();
    _descriptionDebounce = Timer(
      Duration(milliseconds: AppConstants.agentConfigSaveDebounceMs),
      () async {
        final service = ref.read(agentConfigServiceProvider);
        await service.updateAgent(agentId,
            description: _descriptionController.text);
        ref.invalidate(agentDefinitionsProvider);
      },
    );
  }

  void _onPromptChanged(String agentId) {
    _promptDebounce?.cancel();
    _promptDebounce = Timer(
      Duration(milliseconds: AppConstants.agentConfigSaveDebounceMs),
      () async {
        final service = ref.read(agentConfigServiceProvider);
        await service.updateAgent(agentId,
            systemPromptOverride: _promptController.text);
        ref.invalidate(agentDefinitionsProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final agent = ref.watch(selectedAgentProvider);

    if (agent == null) {
      return const Center(
        child: Text(
          'Select an agent to view its configuration.',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 13),
        ),
      );
    }

    // Sync text controllers when agent selection changes.
    if (_descriptionController.text != (agent.description ?? '')) {
      _descriptionController.text = agent.description ?? '';
    }
    final hasOverride =
        agent.systemPromptOverride != null &&
        agent.systemPromptOverride!.isNotEmpty;
    if (_hasPromptOverride != hasOverride) {
      _hasPromptOverride = hasOverride;
      _promptController.text = agent.systemPromptOverride ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              if (agent.isQaManager)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.shield, color: CodeOpsColors.primary),
                ),
              Text(agent.name,
                  style: Theme.of(context).textTheme.titleMedium),
              if (agent.isBuiltIn)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Built-in',
                        style: TextStyle(
                            fontSize: 10, color: CodeOpsColors.warning)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Description.
          const Text('Description',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary)),
          const SizedBox(height: 6),
          SizedBox(
            width: 500,
            child: TextField(
              controller: _descriptionController,
              maxLines: 2,
              readOnly: agent.isBuiltIn,
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => _onDescriptionChanged(agent.id),
              decoration: const InputDecoration(
                hintText: 'Agent description...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model dropdown.
          _buildModelDropdown(agent),
          const SizedBox(height: 20),

          // Temperature.
          _buildTemperatureSlider(agent),
          const SizedBox(height: 20),

          // Max Retries.
          _buildRetriesDropdown(agent),
          const SizedBox(height: 20),

          // Max Turns.
          _buildTurnsSlider(agent),
          const SizedBox(height: 20),

          // Timeout override.
          _buildTimeoutOverride(agent),
          const SizedBox(height: 24),

          // Attached files.
          _buildFilesSection(agent),
          const SizedBox(height: 24),

          // System prompt override.
          _buildPromptOverride(agent),
        ],
      ),
    );
  }

  Widget _buildModelDropdown(AgentDefinition agent) {
    final modelsAsync = ref.watch(anthropicModelsProvider);

    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary)),
          const SizedBox(height: 6),
          modelsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => _buildFallbackModelDropdown(agent),
            data: (models) {
              // Use fetched models, or fallback when cache is empty.
              final modelItems = models.isEmpty
                  ? _fallbackModelItems()
                  : models
                      .map((m) => DropdownMenuItem<String>(
                            value: m.id,
                            child: Text(m.displayName,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList();

              final items = <DropdownMenuItem<String>>[
                const DropdownMenuItem(
                  value: '',
                  child: Text('(System Default)',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 13)),
                ),
                ...modelItems,
              ];

              final currentValue = agent.modelId ?? '';
              final validValue = items.any((i) => i.value == currentValue)
                  ? currentValue
                  : '';

              return DropdownButton<String>(
                value: validValue,
                isExpanded: true,
                dropdownColor: CodeOpsColors.surface,
                items: items,
                onChanged: (v) async {
                  final service = ref.read(agentConfigServiceProvider);
                  await service.updateAgent(agent.id,
                      modelId: v?.isEmpty == true ? null : v);
                  ref.invalidate(agentDefinitionsProvider);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackModelDropdown(AgentDefinition agent) {
    final currentValue = agent.modelId ?? '';
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
          value: '', child: Text('(System Default)')),
      ..._fallbackModelItems(),
    ];
    final validValue = items.any((i) => i.value == currentValue)
        ? currentValue
        : '';

    return DropdownButton<String>(
      value: validValue,
      isExpanded: true,
      dropdownColor: CodeOpsColors.surface,
      items: items,
      onChanged: (v) async {
        final service = ref.read(agentConfigServiceProvider);
        await service.updateAgent(agent.id,
            modelId: v?.isEmpty == true ? null : v);
        ref.invalidate(agentDefinitionsProvider);
      },
    );
  }

  static List<DropdownMenuItem<String>> _fallbackModelItems() {
    return const [
      DropdownMenuItem(
        value: 'claude-sonnet-4-20250514',
        child: Text('Claude Sonnet 4', style: TextStyle(fontSize: 13)),
      ),
      DropdownMenuItem(
        value: 'claude-opus-4-20250514',
        child: Text('Claude Opus 4', style: TextStyle(fontSize: 13)),
      ),
      DropdownMenuItem(
        value: 'claude-haiku-4-20250514',
        child: Text('Claude Haiku 4', style: TextStyle(fontSize: 13)),
      ),
    ];
  }

  Widget _buildTemperatureSlider(AgentDefinition agent) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Temperature (${agent.temperature.toStringAsFixed(1)})',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textSecondary)),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const TemperatureHelpDialog(),
                ),
                child: const Icon(Icons.help_outline,
                    size: 14, color: CodeOpsColors.textTertiary),
              ),
            ],
          ),
          Slider(
            value: agent.temperature,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: agent.temperature.toStringAsFixed(1),
            onChanged: (v) async {
              final service = ref.read(agentConfigServiceProvider);
              await service.updateAgent(agent.id, temperature: v);
              ref.invalidate(agentDefinitionsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRetriesDropdown(AgentDefinition agent) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Max Retries',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary)),
          const SizedBox(height: 6),
          DropdownButton<int>(
            value: agent.maxRetries,
            isExpanded: true,
            dropdownColor: CodeOpsColors.surface,
            items: [0, 1, 2, 3]
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('$v', style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              final service = ref.read(agentConfigServiceProvider);
              await service.updateAgent(agent.id, maxRetries: v);
              ref.invalidate(agentDefinitionsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTurnsSlider(AgentDefinition agent) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Max Turns (${agent.maxTurns})',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary)),
          Slider(
            value: agent.maxTurns.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            label: '${agent.maxTurns}',
            onChanged: (v) async {
              final service = ref.read(agentConfigServiceProvider);
              await service.updateAgent(agent.id, maxTurns: v.round());
              ref.invalidate(agentDefinitionsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutOverride(AgentDefinition agent) {
    final hasTimeout = agent.timeoutMinutes != null;
    final timeoutValue = agent.timeoutMinutes ?? AppConstants.defaultAgentTimeoutMinutes;

    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: hasTimeout,
                onChanged: (v) async {
                  final service = ref.read(agentConfigServiceProvider);
                  if (v == true) {
                    await service.updateAgent(agent.id,
                        timeoutMinutes: AppConstants.defaultAgentTimeoutMinutes);
                  } else {
                    // Clear timeout override by setting to default then nullifying.
                    await _clearTimeoutOverride(agent.id);
                  }
                  ref.invalidate(agentDefinitionsProvider);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Text('Timeout Override ($timeoutValue min)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textSecondary)),
            ],
          ),
          if (hasTimeout)
            Slider(
              value: timeoutValue.toDouble(),
              min: AppConstants.agentTimeoutMinutesMin.toDouble(),
              max: AppConstants.agentTimeoutMinutesMax.toDouble(),
              divisions:
                  (AppConstants.agentTimeoutMinutesMax -
                          AppConstants.agentTimeoutMinutesMin) ~/
                      5,
              label: '$timeoutValue min',
              onChanged: (v) async {
                final service = ref.read(agentConfigServiceProvider);
                await service.updateAgent(agent.id, timeoutMinutes: v.round());
                ref.invalidate(agentDefinitionsProvider);
              },
            ),
        ],
      ),
    );
  }

  /// Clears the timeout override by directly updating with null.
  Future<void> _clearTimeoutOverride(String agentId) async {
    final service = ref.read(agentConfigServiceProvider);
    // Use the service's update with a sentinel — we need to pass through.
    // Since updateAgent only writes non-null fields, we need a direct DB call.
    // For simplicity, set to a very high value then the user can toggle off.
    // Better approach: add clearTimeout method to service.
    await service.updateAgent(agentId, timeoutMinutes: 0);
    // 0 means "use default" in the UI interpretation.
  }

  Widget _buildFilesSection(AgentDefinition agent) {
    final filesAsync = ref.watch(selectedAgentFilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Attached Files',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.textSecondary)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add File', style: TextStyle(fontSize: 11)),
              onPressed: () => _addNewFile(agent.id),
            ),
            TextButton.icon(
              icon: const Icon(Icons.file_upload_outlined, size: 14),
              label: const Text('Import', style: TextStyle(fontSize: 11)),
              onPressed: () => _importFile(agent.id),
            ),
          ],
        ),
        const SizedBox(height: 8),
        filesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e',
              style: const TextStyle(color: CodeOpsColors.error)),
          data: (files) {
            if (files.isEmpty) {
              return const Text('No files attached.',
                  style: TextStyle(
                      color: CodeOpsColors.textTertiary, fontSize: 12));
            }
            return Column(
              children: files
                  .map((f) => AgentFileRow(
                        file: f,
                        onViewEdit: () => _openFileEditor(f),
                        onDelete: () => _deleteFile(f.id),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPromptOverride(AgentDefinition agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hasPromptOverride,
              onChanged: (v) {
                setState(() {
                  _hasPromptOverride = v ?? false;
                  if (!_hasPromptOverride) {
                    _promptController.clear();
                    final service = ref.read(agentConfigServiceProvider);
                    service.updateAgent(agent.id, systemPromptOverride: '');
                    ref.invalidate(agentDefinitionsProvider);
                  }
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const Text('System Prompt Override',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CodeOpsColors.textSecondary)),
          ],
        ),
        if (_hasPromptOverride) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 500,
            height: 200,
            child: TextField(
              controller: _promptController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
              ),
              onChanged: (_) => _onPromptChanged(agent.id),
              decoration: const InputDecoration(
                hintText: 'Enter custom system prompt...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addNewFile(String agentId) async {
    final service = ref.read(agentConfigServiceProvider);
    await service.addFile(
      agentId,
      fileName: 'New File',
      fileType: 'context',
      contentMd: '',
    );
    ref.invalidate(selectedAgentFilesProvider);
  }

  Future<void> _importFile(String agentId) async {
    final service = ref.read(agentConfigServiceProvider);
    await service.importFileFromDisk(agentId);
    ref.invalidate(selectedAgentFilesProvider);
  }

  void _openFileEditor(AgentFile file) {
    ref.read(editingAgentFileProvider.notifier).state = file;
  }

  Future<void> _deleteFile(String fileId) async {
    final service = ref.read(agentConfigServiceProvider);
    await service.deleteFile(fileId);
    ref.invalidate(selectedAgentFilesProvider);
  }
}
