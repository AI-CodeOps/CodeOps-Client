/// Vault Seal & Audit page.
///
/// Two-tab page combining seal management (view status, seal/unseal,
/// manage Shamir key shares) and a filterable, paginated audit log
/// of all vault operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/vault/audit_stats_panel.dart';
import '../widgets/vault/seal_status_display.dart';
import '../widgets/vault/vault_audit_table.dart';

/// The Vault Seal & Audit page with two tabs: Seal Status and Audit Log.
class VaultSealPage extends ConsumerStatefulWidget {
  /// Creates a [VaultSealPage].
  const VaultSealPage({super.key});

  @override
  ConsumerState<VaultSealPage> createState() => _VaultSealPageState();
}

class _VaultSealPageState extends ConsumerState<VaultSealPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (icon: Icons.lock_outline, label: 'Seal Status'),
    (icon: Icons.history, label: 'Audit Log'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'Seal & Audit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 16),

        // Tab bar
        Container(
          color: CodeOpsColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: CodeOpsColors.primary,
            labelColor: CodeOpsColors.textPrimary,
            unselectedLabelColor: CodeOpsColors.textTertiary,
            tabs: _tabs
                .map((t) => Tab(
                      icon: Icon(t.icon, size: 18),
                      text: t.label,
                    ))
                .toList(),
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Seal Status tab
              _buildSealTab(),
              // Audit Log tab
              const SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuditStatsPanel(),
                    SizedBox(height: 16),
                    VaultAuditTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSealTab() {
    final sealAsync = ref.watch(sealStatusProvider);

    return sealAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: CodeOpsColors.primary,
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: CodeOpsColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load seal status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CodeOpsColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(sealStatusProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (status) => SealStatusDisplay(sealStatus: status),
    );
  }
}
