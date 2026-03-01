/// Internal sidebar navigation for Logger pages.
///
/// Displays a vertical list of Logger sub-sections (Dashboard, Log Viewer,
/// Search, Traps, Alerts, Dashboards, Metrics, Traces, Retention) with
/// active-state highlighting based on the current route.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';

/// Logger sub-page sidebar with 9 navigation items.
class LoggerSidebar extends StatelessWidget {
  /// Creates a [LoggerSidebar].
  const LoggerSidebar({super.key});

  /// Navigation items for the Logger module.
  static const _items = <({IconData icon, String label, String path})>[
    (icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/logger'),
    (icon: Icons.list_alt_outlined, label: 'Log Viewer', path: '/logger/viewer'),
    (icon: Icons.search, label: 'Search', path: '/logger/search'),
    (icon: Icons.filter_alt_outlined, label: 'Traps', path: '/logger/traps'),
    (icon: Icons.notifications_outlined, label: 'Alerts', path: '/logger/alerts'),
    (icon: Icons.grid_view_outlined, label: 'Dashboards', path: '/logger/dashboards'),
    (icon: Icons.bar_chart_outlined, label: 'Metrics', path: '/logger/metrics'),
    (icon: Icons.timeline_outlined, label: 'Traces', path: '/logger/traces'),
    (icon: Icons.storage_outlined, label: 'Retention', path: '/logger/retention'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 200,
      color: CodeOpsColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'LOGGER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final item in _items)
                  _LoggerNavItem(
                    icon: item.icon,
                    label: item.label,
                    path: item.path,
                    isActive: _isActive(item.path, currentPath),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns whether [itemPath] matches the [currentPath].
  static bool _isActive(String itemPath, String currentPath) {
    if (itemPath == '/logger') return currentPath == '/logger';
    return currentPath.startsWith(itemPath);
  }
}

class _LoggerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;

  const _LoggerNavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? CodeOpsColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isActive
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                      color: isActive
                          ? CodeOpsColors.textPrimary
                          : CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
