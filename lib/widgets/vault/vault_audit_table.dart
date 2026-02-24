/// Paginated audit log table for the Vault audit log page.
///
/// Displays a paginated [DataTable] of [AuditEntryResponse] entries
/// with [VaultAuditOperationBadge] operation badges, success/fail
/// indicators, expandable [VaultAuditDetailRow] detail panels, and
/// pagination controls. Filtering is handled externally by
/// [VaultAuditFilters].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'vault_audit_detail_row.dart';
import 'vault_audit_operation_badge.dart';

/// Common vault operations for the filter dropdowns.
const vaultAuditOperations = [
  'READ',
  'WRITE',
  'DELETE',
  'LIST',
  'ROTATE',
  'SEAL',
  'UNSEAL',
  'TRANSIT_ENCRYPT',
  'TRANSIT_DECRYPT',
  'CREATE_LEASE',
  'REVOKE_LEASE',
];

/// Resource types for the filter dropdowns.
const vaultAuditResourceTypes = [
  'Secret',
  'Policy',
  'TransitKey',
  'System',
  'Lease',
];

/// Displays a paginated audit log data table.
///
/// Renders a [DataTable] with columns for operation, path, resource
/// type, status, user, correlation ID, and timestamp. Clicking any row
/// toggles an expandable [VaultAuditDetailRow] beneath the table.
/// Pagination controls appear below.
class VaultAuditTable extends ConsumerStatefulWidget {
  /// Creates a [VaultAuditTable].
  const VaultAuditTable({super.key});

  @override
  ConsumerState<VaultAuditTable> createState() => _VaultAuditTableState();
}

class _VaultAuditTableState extends ConsumerState<VaultAuditTable> {
  int? _expandedId;

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(vaultAuditLogProvider);
    final currentPage = ref.watch(vaultAuditPageProvider);

    return auditAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CodeOpsColors.primary,
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                size: 18, color: CodeOpsColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load audit log',
                style: const TextStyle(
                    color: CodeOpsColors.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(vaultAuditLogProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (pageResponse) {
        if (pageResponse.content.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No audit entries found.',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(CodeOpsColors.surfaceVariant),
                columns: const [
                  DataColumn(label: Text('Operation')),
                  DataColumn(label: Text('Path')),
                  DataColumn(label: Text('Resource')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Correlation')),
                  DataColumn(label: Text('Time')),
                ],
                rows: pageResponse.content
                    .map((entry) => _buildRow(entry))
                    .toList(),
              ),
            ),

            // Expanded detail row
            if (_expandedId != null)
              ..._buildExpandedDetail(pageResponse.content),

            const SizedBox(height: 8),

            // Pagination
            _buildPagination(currentPage, pageResponse),
          ],
        );
      },
    );
  }

  DataRow _buildRow(AuditEntryResponse entry) {
    final isExpanded = _expandedId == entry.id;

    return DataRow(
      selected: isExpanded,
      onSelectChanged: (_) => setState(() {
        _expandedId = _expandedId == entry.id ? null : entry.id;
      }),
      cells: [
        // Operation badge
        DataCell(VaultAuditOperationBadge(entry.operation)),
        // Path
        DataCell(
          Tooltip(
            message: entry.path ?? '',
            child: Text(
              _truncate(entry.path ?? '\u2014', 24),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
        ),
        // Resource type
        DataCell(Text(
          entry.resourceType ?? '\u2014',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        )),
        // Success/fail
        DataCell(
          Icon(
            entry.success ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: entry.success ? CodeOpsColors.success : CodeOpsColors.error,
          ),
        ),
        // User
        DataCell(
          Tooltip(
            message: entry.userId ?? '',
            child: Text(
              _truncate(entry.userId ?? '\u2014', 8),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
        ),
        // Correlation ID
        DataCell(
          entry.correlationId != null
              ? InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: entry.correlationId!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correlation ID copied'),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: entry.correlationId!,
                    child: Text(
                      _truncate(entry.correlationId!, 8),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                )
              : const Text('\u2014', style: TextStyle(fontSize: 12)),
        ),
        // Timestamp
        DataCell(Text(
          formatTimeAgo(entry.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        )),
      ],
    );
  }

  List<Widget> _buildExpandedDetail(List<AuditEntryResponse> entries) {
    final entry = entries.where((e) => e.id == _expandedId).firstOrNull;
    if (entry == null) return [];
    return [
      const SizedBox(height: 8),
      VaultAuditDetailRow(entry: entry),
    ];
  }

  Widget _buildPagination(
    int currentPage,
    dynamic pageResponse,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${pageResponse.totalElements} entries',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: currentPage > 0
                  ? () => ref.read(vaultAuditPageProvider.notifier).state =
                      currentPage - 1
                  : null,
            ),
            Text(
              'Page ${currentPage + 1} of ${pageResponse.totalPages}',
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: !pageResponse.isLast
                  ? () => ref.read(vaultAuditPageProvider.notifier).state =
                      currentPage + 1
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }
}
