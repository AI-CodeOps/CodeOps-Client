/// API Key management tab for the Agent Configuration section.
///
/// Provides an obscured API key field with validation, connection testing,
/// and a cached model list display.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/anthropic_model_info.dart';
import '../../providers/agent_config_providers.dart';
import '../../providers/auth_providers.dart';
import '../../theme/colors.dart';

/// Tab content for managing the Anthropic API key and viewing cached models.
class ApiKeyTab extends ConsumerStatefulWidget {
  /// Creates an [ApiKeyTab].
  const ApiKeyTab({super.key});

  @override
  ConsumerState<ApiKeyTab> createState() => _ApiKeyTabState();
}

class _ApiKeyTabState extends ConsumerState<ApiKeyTab> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _testing = false;
  bool _saving = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final key = await ref.read(anthropicApiKeyProvider.future);
    if (key != null && key.isNotEmpty && mounted) {
      _controller.text = key;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() => _testing = true);
    try {
      final service = ref.read(anthropicApiServiceProvider);
      final valid = await service.testApiKey(key);
      if (mounted) {
        ref.read(apiKeyValidatedProvider.notifier).state = valid;
      }
    } catch (_) {
      if (mounted) {
        ref.read(apiKeyValidatedProvider.notifier).state = false;
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() => _saving = true);
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.setAnthropicApiKey(key);
      ref.invalidate(anthropicApiKeyProvider);
      ref.read(apiKeyValidatedProvider.notifier).state = null;

      // Auto-refresh models now that we have a key.
      final service = ref.read(agentConfigServiceProvider);
      await service.refreshModels();
      ref.invalidate(anthropicModelsProvider);
      if (mounted) {
        ref.read(modelFetchFailedProvider.notifier).state = false;
      }
    } catch (_) {
      // Key saved but model refresh may have failed — non-fatal.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refreshModels() async {
    setState(() => _refreshing = true);
    try {
      final service = ref.read(agentConfigServiceProvider);
      await service.refreshModels();
      ref.invalidate(anthropicModelsProvider);
      if (mounted) {
        ref.read(modelFetchFailedProvider.notifier).state = false;
      }
    } catch (_) {
      if (mounted) {
        ref.read(modelFetchFailedProvider.notifier).state = true;
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validated = ref.watch(apiKeyValidatedProvider);
    final modelsAsync = ref.watch(anthropicModelsProvider);
    final fetchFailed = ref.watch(modelFetchFailedProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anthropic API Key',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Required for direct model access. Your key is stored locally in encrypted OS storage.',
            style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // API Key input row.
          SizedBox(
            width: 600,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    obscureText: _obscured,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'sk-ant-...',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscured = !_obscured),
                          ),
                          if (validated != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                validated
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 18,
                                color: validated
                                    ? CodeOpsColors.success
                                    : CodeOpsColors.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _saveKey,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),

          if (fetchFailed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CodeOpsColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: CodeOpsColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to fetch models from Anthropic. Check your API key and network connection.',
                      style:
                          TextStyle(color: CodeOpsColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              Text('Cached Models',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 16),
              IconButton(
                icon: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                onPressed: _refreshing ? null : _refreshModels,
                tooltip: 'Refresh models',
              ),
            ],
          ),
          const SizedBox(height: 8),

          modelsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('Error loading models: $e',
                style: const TextStyle(color: CodeOpsColors.error)),
            data: (models) {
              if (models.isEmpty) {
                return const Text(
                  'No models cached. Save an API key and refresh to load available models.',
                  style: TextStyle(
                      color: CodeOpsColors.textTertiary, fontSize: 13),
                );
              }
              return _ModelsTable(models: models);
            },
          ),
        ],
      ),
    );
  }
}

class _ModelsTable extends StatelessWidget {
  final List<AnthropicModelInfo> models;

  const _ModelsTable({required this.models});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Model',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            Text('Context Window',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text('Max Output',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        ...models.map((model) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(model.displayName,
                    style: const TextStyle(fontSize: 13)),
              ),
              Text(
                model.contextWindow != null
                    ? _formatTokenCount(model.contextWindow!)
                    : '-',
                style: const TextStyle(
                    fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
              Text(
                model.maxOutputTokens != null
                    ? _formatTokenCount(model.maxOutputTokens!)
                    : '-',
                style: const TextStyle(
                    fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
            ],
          );
        }),
      ],
    );
  }

  static String _formatTokenCount(int tokens) {
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}K';
    }
    return tokens.toString();
  }
}
