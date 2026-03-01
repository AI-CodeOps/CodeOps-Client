/// DataLens toolbar — connection selection and quick actions.
///
/// Provides a connection dropdown with color dots, connect/disconnect toggle,
/// refresh schema, new SQL editor tab, and a connection manager button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/datalens/connection_manager_dialog.dart';

/// Toolbar for the DataLens page.
class DatalensToolbar extends ConsumerStatefulWidget {
  /// Creates a [DatalensToolbar].
  const DatalensToolbar({super.key});

  @override
  ConsumerState<DatalensToolbar> createState() => _DatalensToolbarState();
}

class _DatalensToolbarState extends ConsumerState<DatalensToolbar> {
  bool _isBusy = false;

  /// Connects to the currently selected connection.
  Future<void> _connect() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(datalensConnectionServiceProvider);
      await service.connect(connectionId);
      ref.invalidate(datalensSchemasProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Disconnects from the currently selected connection.
  Future<void> _disconnect() async {
    final connectionId = ref.read(selectedConnectionIdProvider);
    if (connectionId == null) return;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(datalensConnectionServiceProvider);
      await service.disconnect(connectionId);
      ref.read(selectedSchemaProvider.notifier).state = null;
      ref.read(selectedTableProvider.notifier).state = null;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Refreshes all schema data for the current connection.
  void _refresh() {
    ref.invalidate(datalensSchemasProvider);
    ref.invalidate(datalensTablesProvider);
    ref.invalidate(datalensColumnsProvider);
  }

  /// Opens the connection manager dialog.
  void _openConnectionManager() {
    showDialog(
      context: context,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const ConnectionManagerDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(datalensConnectionsProvider);
    final selectedConnectionId = ref.watch(selectedConnectionIdProvider);

    // Determine connection status for the selected connection.
    ConnectionStatus? status;
    if (selectedConnectionId != null) {
      final service = ref.read(datalensConnectionServiceProvider);
      status = service.getStatus(selectedConnectionId);
    }
    final isConnected = status == ConnectionStatus.connected;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          // Connection dropdown
          connectionsAsync.when(
            loading: () => const SizedBox(
              width: 200,
              child: Text(
                'Loading...',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
            error: (_, __) => const SizedBox(
              width: 200,
              child: Text(
                'Error loading connections',
                style: TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 12,
                ),
              ),
            ),
            data: (connections) => _ConnectionDropdown(
              connections: connections,
              selectedId: selectedConnectionId,
              onChanged: (id) {
                ref.read(selectedConnectionIdProvider.notifier).state = id;
                ref.read(selectedSchemaProvider.notifier).state = null;
                ref.read(selectedTableProvider.notifier).state = null;
              },
            ),
          ),

          const SizedBox(width: 8),

          // Connect / Disconnect button
          _ToolbarButton(
            icon: isConnected ? Icons.link_off : Icons.link,
            tooltip: isConnected ? 'Disconnect' : 'Connect',
            onPressed: selectedConnectionId == null || _isBusy
                ? null
                : (isConnected ? _disconnect : _connect),
            color: isConnected ? CodeOpsColors.success : null,
          ),

          // Refresh
          _ToolbarButton(
            icon: Icons.refresh,
            tooltip: 'Refresh Schema',
            onPressed: isConnected ? _refresh : null,
          ),

          const SizedBox(width: 4),
          Container(width: 1, height: 20, color: CodeOpsColors.border),
          const SizedBox(width: 4),

          // New SQL Editor
          _ToolbarButton(
            icon: Icons.code,
            tooltip: 'New SQL Editor',
            onPressed: isConnected
                ? () {
                    ref.read(sqlEditorContentProvider.notifier).state = '';
                    ref.read(sqlResultsPanelVisibleProvider.notifier).state =
                        true;
                  }
                : null,
          ),

          const Spacer(),

          // Connection Manager
          TextButton.icon(
            icon: const Icon(Icons.settings, size: 16),
            label: const Text(
              'Connections',
              style: TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: CodeOpsColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            onPressed: _openConnectionManager,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection Dropdown
// ---------------------------------------------------------------------------

class _ConnectionDropdown extends StatelessWidget {
  final List<DatabaseConnection> connections;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ConnectionDropdown({
    required this.connections,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 32,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          hint: const Text(
            'Select connection...',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
          icon: const Icon(
            Icons.expand_more,
            size: 16,
            color: CodeOpsColors.textTertiary,
          ),
          dropdownColor: CodeOpsColors.surfaceVariant,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 12,
          ),
          items: connections.map((conn) {
            final color = conn.color != null
                ? Color(int.parse('FF${conn.color!}', radix: 16))
                : CodeOpsColors.textTertiary;
            return DropdownMenuItem<String>(
              value: conn.id,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conn.name ?? conn.id ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar Button
// ---------------------------------------------------------------------------

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      onPressed: onPressed,
      color: color ?? CodeOpsColors.textSecondary,
      disabledColor: CodeOpsColors.textTertiary.withValues(alpha: 0.5),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
