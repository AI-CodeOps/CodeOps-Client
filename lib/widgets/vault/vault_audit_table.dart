/// Paginated audit log table for the Vault audit log tab.
///
/// Displays a filterable, paginated [DataTable] of [AuditEntryResponse]
/// entries with operation badges, success/fail indicators, expandable
/// error details, and pagination controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';

/// Common vault operations for the filter dropdown.
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

/// Resource types for the filter dropdown.
const vaultAuditResourceTypes = [
  'Secret',
  'Policy',
  'TransitKey',
  'System',
  'Lease',
];

/// Displays a filterable, paginated audit log table.
///
/// Provides dropdowns for operation and resource type filters, a
/// success/failure filter, and a paginated [DataTable] with columns
/// for operation, path, resource type, success, user, correlation ID,
/// and timestamp. Failed entries have expandable error detail rows.
class VaultAuditTable extends ConsumerStatefulWidget {
  /// Creates a [VaultAuditTable].
  const VaultAuditTable({super.key});

  @override
  ConsumerState<VaultAuditTable> createState() => _VaultAuditTableState();
}

class _VaultAuditTableState extends ConsumerState<VaultAuditTable> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(vaultAuditLogProvider);
    final operationFilter = ref.watch(vaultAuditOperationFilterProvider);
    final resourceFilter = ref.watch(vaultAuditResourceTypeFilterProvider);
    final successFilter = ref.watch(vaultAuditSuccessOnlyProvider);
    final currentPage = ref.watch(vaultAuditPageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            // Operation filter
            SizedBox(
              width: 180,
              child: DropdownButton<String>(
                value:
                    operationFilter.isEmpty ? null : operationFilter,
                isExpanded: true,
                hint: const Text('Operation',
                    style: TextStyle(fontSize: 13)),
                dropdownColor: CodeOpsColors.surface,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All Operations'),
                  ),
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
            ),
            // Resource type filter
            SizedBox(
              width: 160,
              child: DropdownButton<String>(
                value:
                    resourceFilter.isEmpty ? null : resourceFilter,
                isExpanded: true,
                hint: const Text('Resource',
                    style: TextStyle(fontSize: 13)),
                dropdownColor: CodeOpsColors.surface,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All Resources'),
                  ),
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
            ),
            // Success filter
            SizedBox(
              width: 150,
              child: DropdownButton<bool?>(
                value: successFilter,
                isExpanded: true,
                hint: const Text('Success',
                    style: TextStyle(fontSize: 13)),
                dropdownColor: CodeOpsColors.surface,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: true, child: Text('Success Only')),
                  DropdownMenuItem(
                      value: false, child: Text('Failures Only')),
                ],
                onChanged: (v) {
                  ref.read(vaultAuditSuccessOnlyProvider.notifier).state = v;
                  ref.read(vaultAuditPageProvider.notifier).state = 0;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        auditAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.primary,
              ),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load audit log: $e',
            style:
                const TextStyle(color: CodeOpsColors.error, fontSize: 13),
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
                const SizedBox(height: 8),
                // Expanded error detail
                ..._buildExpandedErrors(pageResponse.content),
                const SizedBox(height: 8),
                // Pagination
                _buildPagination(currentPage, pageResponse),
              ],
            );
          },
        ),
      ],
    );
  }

  DataRow _buildRow(AuditEntryResponse entry) {
    final opColor = _operationColor(entry.operation);
    final entryKey = '${entry.id}';

    return DataRow(
      onSelectChanged: entry.errorMessage != null
          ? (_) => setState(() {
                _expandedId = _expandedId == entryKey ? null : entryKey;
              })
          : null,
      cells: [
        // Operation badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: opColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.operation,
              style: TextStyle(
                fontSize: 11,
                color: opColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
              : const Text('\u2014',
                  style: TextStyle(fontSize: 12)),
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

  List<Widget> _buildExpandedErrors(List<AuditEntryResponse> entries) {
    return entries
        .where(
          (e) => e.errorMessage != null && '${e.id}' == _expandedId,
        )
        .map(
          (e) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: CodeOpsColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              e.errorMessage!,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.error,
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildPagination(
    int currentPage,
    dynamic pageResponse,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: currentPage > 0
              ? () =>
                  ref.read(vaultAuditPageProvider.notifier).state =
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
              ? () =>
                  ref.read(vaultAuditPageProvider.notifier).state =
                      currentPage + 1
              : null,
        ),
      ],
    );
  }

  static Color _operationColor(String op) {
    final upper = op.toUpperCase();
    if (upper.contains('READ') || upper.contains('LIST')) {
      return CodeOpsColors.success;
    }
    if (upper.contains('WRITE') || upper.contains('CREATE')) {
      return const Color(0xFF3B82F6);
    }
    if (upper.contains('DELETE') || upper.contains('REVOKE')) {
      return CodeOpsColors.error;
    }
    if (upper.contains('SEAL') || upper.contains('UNSEAL')) {
      return CodeOpsColors.warning;
    }
    if (upper.contains('ENCRYPT') || upper.contains('DECRYPT')) {
      return const Color(0xFFA855F7);
    }
    if (upper.contains('ROTATE')) {
      return CodeOpsColors.secondary;
    }
    return CodeOpsColors.textTertiary;
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }
}
