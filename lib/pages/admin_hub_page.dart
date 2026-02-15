/// Admin Hub page.
///
/// Provides tabbed access to user management, system settings,
/// audit log, and usage statistics. Restricted to ADMIN/OWNER roles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../widgets/admin/audit_log_tab.dart';
import '../widgets/admin/settings_management_tab.dart';
import '../widgets/admin/usage_stats_tab.dart';
import '../widgets/admin/user_management_tab.dart';

/// The admin hub page with tabbed management sections.
class AdminHubPage extends ConsumerStatefulWidget {
  /// Creates an [AdminHubPage].
  const AdminHubPage({super.key});

  @override
  ConsumerState<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends ConsumerState<AdminHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (icon: Icons.people_outline, label: 'Users'),
    (icon: Icons.settings_outlined, label: 'System Settings'),
    (icon: Icons.history, label: 'Audit Log'),
    (icon: Icons.analytics_outlined, label: 'Usage Stats'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      ref.read(adminTabIndexProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access control: check user role
    final membersAsync = ref.watch(teamMembersProvider);
    final currentUser = ref.watch(currentUserProvider);

    final hasAccess = membersAsync.whenOrNull(
          data: (members) {
            final me =
                members.where((m) => m.userId == currentUser?.id).firstOrNull;
            return me != null &&
                (me.role == TeamRole.owner || me.role == TeamRole.admin);
          },
        ) ??
        false;

    if (!hasAccess) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: CodeOpsColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Admin Hub requires Owner or Admin role.',
              style: TextStyle(
                fontSize: 14,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'Admin Hub',
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
            children: const [
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: UserManagementTab(),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: SettingsManagementTab(),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: AuditLogTab(),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: UsageStatsTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
