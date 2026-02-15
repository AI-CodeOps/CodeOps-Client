/// Admin usage statistics tab.
///
/// Displays metric cards from the usage stats API response.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_providers.dart';
import '../../theme/colors.dart';

/// Displays team usage statistics as metric cards.
class UsageStatsTab extends ConsumerWidget {
  /// Creates a [UsageStatsTab].
  const UsageStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(usageStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Text(
        'Failed to load usage stats: $e',
        style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
      ),
      data: (stats) {
        if (stats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No usage data available.',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
              ),
            ),
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              label: 'Total Users',
              value: _extractInt(stats, 'totalUsers'),
              icon: Icons.people_outline,
              color: CodeOpsColors.primary,
            ),
            _StatCard(
              label: 'Active Users',
              value: _extractInt(stats, 'activeUsers'),
              icon: Icons.person_outline,
              color: CodeOpsColors.success,
            ),
            _StatCard(
              label: 'Total Teams',
              value: _extractInt(stats, 'totalTeams'),
              icon: Icons.group_outlined,
              color: CodeOpsColors.secondary,
            ),
            _StatCard(
              label: 'Total Projects',
              value: _extractInt(stats, 'totalProjects'),
              icon: Icons.folder_outlined,
              color: CodeOpsColors.warning,
            ),
            // Render any additional keys not in the known set
            ...stats.entries
                .where((e) => !_knownKeys.contains(e.key))
                .map((e) => _StatCard(
                      label: _formatKey(e.key),
                      value: '${e.value}',
                      icon: Icons.analytics_outlined,
                      color: CodeOpsColors.textSecondary,
                    )),
          ],
        );
      },
    );
  }

  static String _extractInt(Map<String, dynamic> stats, String key) {
    final val = stats[key];
    if (val == null) return '-';
    return '$val';
  }

  static String _formatKey(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  static const _knownKeys = {
    'totalUsers',
    'activeUsers',
    'totalTeams',
    'totalProjects',
  };
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
