/// Dialog for connecting a container to a Docker network.
///
/// Displays a dropdown of available containers and lets the user
/// pick one. Returns the selected container ID on submission,
/// or `null` if cancelled.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// A dialog that lets the user pick a container to connect to a network.
///
/// Returns the selected container ID when submitted,
/// or `null` if cancelled.
class ConnectContainerDialog extends StatefulWidget {
  /// Available container instances to choose from.
  final List<FleetContainerInstance> containers;

  /// Container IDs already connected (to filter out).
  final Set<String> connectedIds;

  /// Creates a [ConnectContainerDialog].
  const ConnectContainerDialog({
    super.key,
    required this.containers,
    required this.connectedIds,
  });

  /// Shows the dialog and returns the result.
  static Future<String?> show(
    BuildContext context, {
    required List<FleetContainerInstance> containers,
    required Set<String> connectedIds,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ConnectContainerDialog(
        containers: containers,
        connectedIds: connectedIds,
      ),
    );
  }

  @override
  State<ConnectContainerDialog> createState() =>
      _ConnectContainerDialogState();
}

class _ConnectContainerDialogState extends State<ConnectContainerDialog> {
  String? _selectedContainerId;

  /// Containers not already connected to this network.
  late final List<FleetContainerInstance> _filteredContainers;

  @override
  void initState() {
    super.initState();
    _filteredContainers = widget.containers
        .where((c) =>
            c.id != null && !widget.connectedIds.contains(c.id))
        .toList();
  }

  /// Submits the form.
  void _submit() {
    if (_selectedContainerId == null) return;
    Navigator.of(context).pop(_selectedContainerId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Connect Container'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_filteredContainers.isEmpty) ...[
              const Text(
                'All containers are already connected to this network.',
                style: TextStyle(color: CodeOpsColors.textSecondary),
              ),
            ] else ...[
              const Text(
                'Select a container to connect:',
                style: TextStyle(color: CodeOpsColors.textSecondary),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedContainerId,
                decoration:
                    const InputDecoration(labelText: 'Container *'),
                dropdownColor: CodeOpsColors.surfaceVariant,
                items: _filteredContainers
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.containerName ?? c.id ?? '',
                            style: CodeOpsTypography.bodyMedium,
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedContainerId = v),
              ),
            ],
          ],
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
        if (_filteredContainers.isNotEmpty)
          ElevatedButton(
            onPressed:
                _selectedContainerId != null ? _submit : null,
            child: const Text('Connect'),
          ),
      ],
    );
  }
}
