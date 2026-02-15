/// Navigation shell wrapping all authenticated routes.
///
/// Provides a collapsible sidebar (left), top bar (above content),
/// and a content area for the current route's child widget.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/enums.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import 'team_switcher_dialog.dart';

/// The main application shell with sidebar navigation and top bar.
class NavigationShell extends ConsumerStatefulWidget {
  /// The child widget from GoRouter's ShellRoute.
  final Widget child;

  /// Creates a [NavigationShell].
  const NavigationShell({super.key, required this.child});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  @override
  Widget build(BuildContext context) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final sidebarWidth = collapsed ? 64.0 : 240.0;

    return Scaffold(
      backgroundColor: CodeOpsColors.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            child: _Sidebar(collapsed: collapsed),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends ConsumerWidget {
  final bool collapsed;

  const _Sidebar({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        children: [
          // Logo + collapse toggle
          _SidebarHeader(collapsed: collapsed),
          const Divider(height: 1),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader('NAVIGATE', collapsed),
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  path: '/',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  path: '/projects',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _SectionHeader('SOURCE', collapsed),
                _NavItem(
                  icon: Icons.code,
                  label: 'GitHub Browser',
                  path: '/repos',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _SectionHeader('ANALYZE', collapsed),
                _NavItem(
                  icon: Icons.security,
                  label: 'Audit',
                  path: '/audit',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.verified_outlined,
                  label: 'Compliance',
                  path: '/compliance',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Dependencies',
                  path: '/dependencies',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.bug_report_outlined,
                  label: 'Bug Investigator',
                  path: '/bugs',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _SectionHeader('MAINTAIN', collapsed),
                _NavItem(
                  icon: Icons.view_kanban_outlined,
                  label: 'Jira Browser',
                  path: '/bugs/jira',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.task_outlined,
                  label: 'Tasks',
                  path: '/tasks',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Tech Debt',
                  path: '/tech-debt',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _SectionHeader('MONITOR', collapsed),
                _NavItem(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Health',
                  path: '/health',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.history,
                  label: 'Job History',
                  path: '/history',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _SectionHeader('TEAM', collapsed),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Personas',
                  path: '/personas',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.rule,
                  label: 'Directives',
                  path: '/directives',
                  currentPath: currentPath,
                  collapsed: collapsed,
                ),
              ],
            ),
          ),

          // Bottom section
          const Divider(height: 1),
          _BottomSection(collapsed: collapsed),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar Header
// ---------------------------------------------------------------------------

class _SidebarHeader extends ConsumerWidget {
  final bool collapsed;

  const _SidebarHeader({required this.collapsed});

  /// Extra left padding on macOS to clear the native traffic-light buttons
  /// when using [TitleBarStyle.hidden].
  static final double _macOsTrafficLightWidth = Platform.isMacOS ? 70.0 : 0.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leftPad = collapsed
        ? (_macOsTrafficLightWidth > 0 ? _macOsTrafficLightWidth : 8.0)
        : (_macOsTrafficLightWidth > 0 ? _macOsTrafficLightWidth : 16.0);

    return SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad, right: collapsed ? 8 : 16),
        child: Row(
          children: [
            const Icon(
              Icons.terminal,
              color: CodeOpsColors.primary,
              size: 24,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'CodeOps',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              icon: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                size: 18,
                color: CodeOpsColors.textTertiary,
              ),
              onPressed: () {
                ref.read(sidebarCollapsedProvider.notifier).state = !collapsed;
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool collapsed;

  const _SectionHeader(this.title, this.collapsed);

  @override
  Widget build(BuildContext context) {
    if (collapsed) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: CodeOpsColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav Item
// ---------------------------------------------------------------------------

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool collapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.collapsed,
  });

  bool get _isActive {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive;

    final child = Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? CodeOpsColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: active
            ? const Border(
                left: BorderSide(color: CodeOpsColors.primary, width: 3),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.go(path),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
            child: Row(
              mainAxisAlignment:
                  collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                        color: active
                            ? CodeOpsColors.textPrimary
                            : CodeOpsColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(message: label, child: child);
    }
    return child;
  }
}

// ---------------------------------------------------------------------------
// Bottom Section (Settings, Admin, User profile)
// ---------------------------------------------------------------------------

class _BottomSection extends ConsumerWidget {
  final bool collapsed;

  const _BottomSection({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final user = ref.watch(currentUserProvider);
    final membersAsync = ref.watch(teamMembersProvider);

    // Check if current user is OWNER or ADMIN
    final isAdminOrOwner = membersAsync.whenOrNull(
          data: (members) {
            if (user == null) return false;
            final me = members.where((m) => m.userId == user.id).firstOrNull;
            return me != null &&
                (me.role == TeamRole.owner || me.role == TeamRole.admin);
          },
        ) ??
        false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            path: '/settings',
            currentPath: currentPath,
            collapsed: collapsed,
          ),
          if (isAdminOrOwner)
            _NavItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              path: '/admin',
              currentPath: currentPath,
              collapsed: collapsed,
            ),
          const SizedBox(height: 8),
          _UserProfile(collapsed: collapsed),
        ],
      ),
    );
  }
}

class _UserProfile extends ConsumerWidget {
  final bool collapsed;

  const _UserProfile({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final initials = _getInitials(user?.displayName ?? '?');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        offset: collapsed ? const Offset(64, 0) : const Offset(0, -80),
        color: CodeOpsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CodeOpsColors.border),
        ),
        onSelected: (value) async {
          if (value == 'switch_team') {
            showDialog(
              context: context,
              builder: (_) => const TeamSwitcherDialog(),
            );
          } else if (value == 'logout') {
            final authService = ref.read(authServiceProvider);
            await authService.logout();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'switch_team',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 16, color: CodeOpsColors.textSecondary),
                SizedBox(width: 8),
                Text('Switch Team'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 16, color: CodeOpsColors.error),
                SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: CodeOpsColors.error)),
              ],
            ),
          ),
        ],
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 8),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: CodeOpsColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user?.displayName ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.unfold_more,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Top Bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final pageName = _pageNameFromPath(path);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            pageName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: () {},
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Badge(
              label: Text('0', style: TextStyle(fontSize: 9)),
              child: Icon(Icons.notifications_none, size: 18),
            ),
            color: CodeOpsColors.textSecondary,
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: () {
              launchUrl(Uri.parse('https://docs.codeops.dev'));
            },
            tooltip: 'Documentation',
          ),
        ],
      ),
    );
  }

  static String _pageNameFromPath(String path) {
    if (path == '/') return 'Home';
    final routes = <String, String>{
      '/projects': 'Projects',
      '/repos': 'GitHub Browser',
      '/audit': 'Audit Wizard',
      '/compliance': 'Compliance',
      '/dependencies': 'Dependencies',
      '/bugs': 'Bug Investigator',
      '/bugs/jira': 'Jira Browser',
      '/tasks': 'Tasks',
      '/tech-debt': 'Tech Debt',
      '/health': 'Health Dashboard',
      '/history': 'Job History',
      '/personas': 'Personas',
      '/directives': 'Directives',
      '/settings': 'Settings',
      '/admin': 'Admin Hub',
    };
    // Check exact match first, then prefix matches for parameterized routes
    if (routes.containsKey(path)) return routes[path]!;
    if (path.startsWith('/projects/')) return 'Project Detail';
    if (path.startsWith('/jobs/') && path.endsWith('/report')) return 'Job Report';
    if (path.startsWith('/jobs/') && path.endsWith('/findings')) {
      return 'Findings Explorer';
    }
    if (path.startsWith('/jobs/') && path.endsWith('/tasks')) return 'Task List';
    if (path.startsWith('/jobs/')) return 'Job Progress';
    if (path.startsWith('/personas/')) return 'Persona Editor';
    return 'CodeOps';
  }
}
