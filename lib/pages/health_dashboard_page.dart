/// Health Dashboard page.
///
/// Displays team health overview, per-project health cards,
/// project-specific trend panel, and schedule management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_providers.dart';
import '../providers/project_providers.dart';
import '../theme/colors.dart';
import '../widgets/health/health_overview_panel.dart';
import '../widgets/health/health_trend_panel.dart';
import '../widgets/health/schedule_manager_panel.dart';

/// The health dashboard page showing team and project health data.
class HealthDashboardPage extends ConsumerStatefulWidget {
  /// Creates a [HealthDashboardPage].
  const HealthDashboardPage({super.key});

  @override
  ConsumerState<HealthDashboardPage> createState() =>
      _HealthDashboardPageState();
}

class _HealthDashboardPageState extends ConsumerState<HealthDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Auto-select first project if none selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectProject();
    });
  }

  void _autoSelectProject() {
    final selected = ref.read(selectedHealthProjectProvider);
    if (selected != null) return;

    final projectsAsync = ref.read(teamProjectsProvider);
    projectsAsync.whenData((projects) {
      final active = projects.where((p) => p.isArchived != true).toList();
      if (active.isNotEmpty) {
        ref.read(selectedHealthProjectProvider.notifier).state = active.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedProjectId = ref.watch(selectedHealthProjectProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Text(
            'Health Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Team overview + project cards
          const HealthOverviewPanel(),
          const SizedBox(height: 32),

          // Project detail panel (trend + schedules)
          if (selectedProjectId != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CodeOpsColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CodeOpsColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthTrendPanel(projectId: selectedProjectId),
                  const SizedBox(height: 32),
                  const Divider(color: CodeOpsColors.border),
                  const SizedBox(height: 16),
                  ScheduleManagerPanel(projectId: selectedProjectId),
                ],
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Select a project above to view trends and schedules.',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
