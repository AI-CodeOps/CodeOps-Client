/// DataLens status bar — connection info and query statistics.
///
/// Displays connection status, database/host/port/user info, current schema,
/// table count, and last query execution time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_enums.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// Status bar at the bottom of the DataLens page.
class DatalensStatusBar extends ConsumerWidget {
  /// Creates a [DatalensStatusBar].
  const DatalensStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConnectionId = ref.watch(selectedConnectionIdProvider);
    final selectedSchema = ref.watch(selectedSchemaProvider);
    final tablesAsync = ref.watch(datalensTablesProvider);
    final queryResult = ref.watch(datalensQueryResultProvider);

    // Connection status.
    ConnectionStatus status = ConnectionStatus.disconnected;
    if (selectedConnectionId != null) {
      final service = ref.read(datalensConnectionServiceProvider);
      status = service.getStatus(selectedConnectionId);
    }

    // Connection details from the provider.
    final connectionsAsync = ref.watch(datalensConnectionsProvider);
    String? host;
    int? port;
    String? database;
    String? username;
    connectionsAsync.whenData((connections) {
      final conn = connections
          .where((c) => c.id == selectedConnectionId)
          .firstOrNull;
      if (conn != null) {
        host = conn.host;
        port = conn.port;
        database = conn.database;
        username = conn.username;
      }
    });

    final tableCount = tablesAsync.valueOrNull?.length;
    final lastQueryTimeMs = queryResult?.executionTimeMs;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          // Connection status indicator
          _StatusDot(status: status),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),

          if (selectedConnectionId != null &&
              status == ConnectionStatus.connected) ...[
            const _Separator(),
            // Database info
            if (database != null) ...[
              const Icon(
                Icons.storage_outlined,
                size: 12,
                color: CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                database!,
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],

            if (host != null) ...[
              const _Separator(),
              Text(
                '$host:${port ?? 5432}',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],

            if (username != null) ...[
              const _Separator(),
              const Icon(
                Icons.person_outline,
                size: 12,
                color: CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                username!,
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],

            if (selectedSchema != null) ...[
              const _Separator(),
              Text(
                'Schema: $selectedSchema',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],

            if (tableCount != null) ...[
              const _Separator(),
              Text(
                '$tableCount tables',
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ],

          const Spacer(),

          // Last query time
          if (lastQueryTimeMs != null)
            Text(
              'Last query: ${lastQueryTimeMs}ms',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Dot
// ---------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  final ConnectionStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ConnectionStatus.connected => CodeOpsColors.success,
      ConnectionStatus.connecting => CodeOpsColors.warning,
      ConnectionStatus.error => CodeOpsColors.error,
      ConnectionStatus.disconnected => CodeOpsColors.textTertiary,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Separator
// ---------------------------------------------------------------------------

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: TextStyle(
          fontSize: 11,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}
