// Unified home dashboard page.
//
// Displays module health cards, recent activity, quick actions,
// fleet status summary, relay unread counts, and session timeline.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../theme/colors.dart';
import '../widgets/home/fleet_status_summary.dart';
import '../widgets/home/module_health_card.dart';
import '../widgets/home/quick_actions_panel.dart';
import '../widgets/home/relay_unread_summary.dart';
import '../widgets/mcp/activity_feed_widget.dart';

/// The unified home dashboard page.
class HomePage extends ConsumerStatefulWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh dashboard data every 30 seconds.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(moduleHealthProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(moduleHealthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final greeting = _greeting();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, ${user?.displayName ?? 'Engineer'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh dashboard',
                    style: IconButton.styleFrom(
                      foregroundColor: CodeOpsColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Module Health Cards ──────────────────────────────────
              const _ModuleHealthSection(),
              const SizedBox(height: 24),

              // ── Recent Activity + Quick Actions ─────────────────────
              if (narrow) ...[
                const _RecentActivitySection(),
                const SizedBox(height: 16),
                const QuickActionsPanel(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 3, child: _RecentActivitySection()),
                    const SizedBox(width: 16),
                    const Expanded(flex: 2, child: QuickActionsPanel()),
                  ],
                ),
              const SizedBox(height: 24),

              // ── Fleet Status + Relay Unread ─────────────────────────
              if (narrow) ...[
                const FleetStatusSummary(),
                const SizedBox(height: 16),
                const RelayUnreadSummary(),
              ] else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: FleetStatusSummary()),
                    SizedBox(width: 16),
                    Expanded(child: RelayUnreadSummary()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module Health Section
// ─────────────────────────────────────────────────────────────────────────────

class _ModuleHealthSection extends ConsumerWidget {
  const _ModuleHealthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(moduleHealthProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Module Health',
          style: TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        healthAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CodeOpsColors.primary,
              ),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Failed to load module health',
              style: TextStyle(color: CodeOpsColors.error, fontSize: 12),
            ),
          ),
          data: (modules) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < modules.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  ModuleHealthCard(health: modules[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Section (wraps ActivityFeedWidget from CMF-003)
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 300,
            child: ActivityFeedWidget(maxItems: 10, showFilters: false),
          ),
        ],
      ),
    );
  }
}
