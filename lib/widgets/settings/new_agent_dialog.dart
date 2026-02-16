/// Dialog for creating a new custom agent definition.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/agent_config_providers.dart';
import '../../theme/colors.dart';

/// An [AlertDialog] for creating a new custom agent.
class NewAgentDialog extends ConsumerStatefulWidget {
  /// Creates a [NewAgentDialog].
  const NewAgentDialog({super.key});

  @override
  ConsumerState<NewAgentDialog> createState() => _NewAgentDialogState();
}

class _NewAgentDialogState extends ConsumerState<NewAgentDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final service = ref.read(agentConfigServiceProvider);
      final agent = await service.createAgent(
        name: name,
        description: _descriptionController.text.trim(),
      );
      ref.invalidate(agentDefinitionsProvider);
      ref.read(selectedAgentIdProvider.notifier).state = agent.id;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = 'Failed to create agent.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Agent'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. My Custom Agent',
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What does this agent do?',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      const TextStyle(color: CodeOpsColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _create,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
