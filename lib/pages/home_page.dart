/// Home dashboard page.
///
/// Displays a time-of-day greeting, quick-start cards, recent activity,
/// project health grid, and team metrics overview.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_providers.dart';
import '../widgets/dashboard/quick_start_cards.dart';
import '../widgets/dashboard/recent_activity.dart';
import '../widgets/dashboard/project_health_grid.dart';
import '../widgets/dashboard/team_overview.dart';

/// The home dashboard page.
class HomePage extends ConsumerWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Greeting
              Text(
                '$greeting, ${user?.displayName ?? 'Engineer'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Quick Start Cards
              const QuickStartCards(),
              const SizedBox(height: 24),

              // Recent Activity + Project Health
              if (narrow) ...[
                SizedBox(
                  height: 400,
                  child: const RecentActivity(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: const ProjectHealthGrid(),
                ),
              ] else
                SizedBox(
                  height: 400,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: RecentActivity()),
                      const SizedBox(width: 16),
                      const Expanded(child: ProjectHealthGrid()),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Team Overview
              const TeamOverview(),
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
