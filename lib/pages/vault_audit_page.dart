/// Vault Audit Log Viewer page.
///
/// Full-page layout composing [AuditStatsPanel], [VaultAuditFilters],
/// and [VaultAuditTable] with a header containing title, refresh, and
/// export actions. This is the dedicated audit log page accessible
/// from the Vault navigation sidebar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/vault/audit_stats_panel.dart';
import '../widgets/vault/vault_audit_export.dart';
import '../widgets/vault/vault_audit_filters.dart';
import '../widgets/vault/vault_audit_table.dart';

/// The Vault Audit Log Viewer page.
///
/// Displays audit statistics, a comprehensive filter bar, and a
/// paginated data table of audit entries. The header provides refresh
/// and export buttons.
class VaultAuditPage extends ConsumerWidget {
  /// Creates a [VaultAuditPage].
  const VaultAuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(vaultAuditLogProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.receipt_long, color: CodeOpsColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Audit Log',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(vaultAuditLogProvider);
                  ref.invalidate(vaultAuditStatsProvider);
                },
              ),
              const SizedBox(width: 4),
              // Export button
              OutlinedButton.icon(
                onPressed: auditAsync.valueOrNull?.content.isNotEmpty == true
                    ? () => VaultAuditExport.showExportDialog(
                          context,
                          auditAsync.value!.content,
                        )
                    : null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats panel
          const AuditStatsPanel(),
          const SizedBox(height: 16),

          // Filters
          const VaultAuditFilters(),
          const SizedBox(height: 16),

          // Table
          const Expanded(
            child: SingleChildScrollView(
              child: VaultAuditTable(),
            ),
          ),
        ],
      ),
    );
  }
}
