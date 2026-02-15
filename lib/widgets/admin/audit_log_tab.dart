/// Admin audit log tab.
///
/// Displays a paginated data table of audit log entries with
/// action filters and expandable detail rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_providers.dart';
import '../../theme/colors.dart';

/// Displays the team audit log with filters and pagination.
class AuditLogTab extends ConsumerWidget {
  /// Creates an [AuditLogTab].
  const AuditLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(teamAuditLogProvider);
    final actionFilter = ref.watch(auditLogActionFilterProvider);
    final currentPage = ref.watch(auditLogPageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters row
        Row(
          children: [
            // Action filter dropdown
            SizedBox(
              width: 200,
              child: DropdownButton<String?>(
                value: actionFilter,
                isExpanded: true,
                hint: const Text('Filter by action',
                    style: TextStyle(fontSize: 13)),
                dropdownColor: CodeOpsColors.surface,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Actions'),
                  ),
                  ..._commonActions.map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a, style: const TextStyle(fontSize: 13)),
                      )),
                ],
                onChanged: (v) =>
                    ref.read(auditLogActionFilterProvider.notifier).state = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Audit log table
        auditAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load audit log: $e',
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
          ),
          data: (pageResponse) {
            var entries = pageResponse.content;

            // Client-side action filter
            if (actionFilter != null) {
              entries = entries
                  .where((e) =>
                      e.action.toLowerCase() == actionFilter.toLowerCase())
                  .toList();
            }

            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No audit log entries found.',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 13,
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
                      DataColumn(label: Text('Timestamp')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Entity Type')),
                      DataColumn(label: Text('Entity ID')),
                      DataColumn(label: Text('Details')),
                      DataColumn(label: Text('IP')),
                    ],
                    rows: entries.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            entry.createdAt != null
                                ? DateFormat('M/d/yy HH:mm:ss')
                                    .format(entry.createdAt!)
                                : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CodeOpsColors.textSecondary,
                            ),
                          )),
                          DataCell(Text(
                            entry.userName ?? entry.userId ?? '-',
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    CodeOpsColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.action,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: CodeOpsColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                            entry.entityType ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CodeOpsColors.textSecondary,
                            ),
                          )),
                          DataCell(
                            entry.entityId != null
                                ? Tooltip(
                                    message: entry.entityId!,
                                    child: Text(
                                      _truncateId(entry.entityId!),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: CodeOpsColors.textTertiary,
                                      ),
                                    ),
                                  )
                                : const Text('-',
                                    style: TextStyle(fontSize: 12)),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Tooltip(
                                message: entry.details ?? '',
                                child: Text(
                                  entry.details ?? '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CodeOpsColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                            entry.ipAddress ?? '-',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: CodeOpsColors.textTertiary,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: currentPage > 0
                          ? () => ref
                              .read(auditLogPageProvider.notifier)
                              .state = currentPage - 1
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
                          ? () => ref
                              .read(auditLogPageProvider.notifier)
                              .state = currentPage + 1
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  static const _commonActions = [
    'LOGIN',
    'LOGOUT',
    'CREATE',
    'UPDATE',
    'DELETE',
    'INVITE',
    'ACTIVATE',
    'DEACTIVATE',
  ];
}
