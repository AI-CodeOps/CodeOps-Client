/// Audit Wizard page.
///
/// Composes [WizardScaffold] with 4 steps: Source, Agents, Configuration,
/// and Review. On launch: checks Claude Code status, builds config JSON,
/// calls [JobOrchestrator.executeJob] (fire-and-forget), and navigates
/// to `/jobs/{jobId}`. Defaults to all 12 agents selected.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/agent_providers.dart';
import '../providers/wizard_providers.dart';
import '../services/orchestration/agent_dispatcher.dart';
import '../services/orchestration/job_orchestrator.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/wizard/agent_selector_step.dart';
import '../widgets/wizard/review_step.dart';
import '../widgets/wizard/source_step.dart';
import '../widgets/wizard/threshold_step.dart';
import '../widgets/wizard/wizard_scaffold.dart';

/// The Audit Wizard page for launching a full project audit.
class AuditWizardPage extends ConsumerStatefulWidget {
  /// Creates an [AuditWizardPage].
  const AuditWizardPage({super.key});

  @override
  ConsumerState<AuditWizardPage> createState() => _AuditWizardPageState();
}

class _AuditWizardPageState extends ConsumerState<AuditWizardPage> {
  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(auditWizardStateProvider);
    final notifier = ref.read(auditWizardStateProvider.notifier);

    final steps = [
      WizardStepDef(
        title: 'Source',
        subtitle: 'Project & branch',
        icon: Icons.folder_outlined,
        isValid: wizardState.selectedProject != null &&
            wizardState.selectedBranch != null,
        content: SourceStep(
          selectedProject: wizardState.selectedProject,
          selectedBranch: wizardState.selectedBranch,
          onProjectSelected: notifier.selectProject,
          onBranchSelected: notifier.selectBranch,
        ),
      ),
      WizardStepDef(
        title: 'Agents',
        subtitle: '${wizardState.selectedAgents.length} selected',
        icon: Icons.smart_toy_outlined,
        isValid: wizardState.selectedAgents.isNotEmpty,
        content: AgentSelectorStep(
          selectedAgents: wizardState.selectedAgents,
          onToggle: notifier.toggleAgent,
          onSelectAll: notifier.selectAllAgents,
          onSelectNone: notifier.selectNoAgents,
          onSelectRecommended: () =>
              notifier.selectRecommendedAgents(JobMode.audit),
        ),
      ),
      WizardStepDef(
        title: 'Configuration',
        subtitle: 'Thresholds & model',
        icon: Icons.tune,
        content: ThresholdStep(
          config: wizardState.config,
          onConfigChanged: notifier.updateConfig,
        ),
      ),
      WizardStepDef(
        title: 'Review',
        subtitle: 'Confirm & launch',
        icon: Icons.rocket_launch,
        content: ReviewStep(
          project: wizardState.selectedProject,
          branch: wizardState.selectedBranch,
          selectedAgents: wizardState.selectedAgents,
          config: wizardState.config,
        ),
      ),
    ];

    return WizardScaffold(
      title: 'Audit Wizard',
      steps: steps,
      currentStep: wizardState.currentStep,
      isLaunching: wizardState.isLaunching,
      launchLabel: 'Launch Audit',
      onBack: () => notifier.previousStep(),
      onNext: () => notifier.nextStep(),
      onLaunch: () => _launchAudit(wizardState),
      onCancel: () {
        notifier.reset();
        context.go('/');
      },
    );
  }

  Future<void> _launchAudit(AuditWizardState wizardState) async {
    final notifier = ref.read(auditWizardStateProvider.notifier);
    final orchestrator = ref.read(jobOrchestratorProvider);
    final project = wizardState.selectedProject;

    if (project == null) return;

    notifier.setLaunching(true);

    try {
      // Build config
      final dispatchConfig = AgentDispatchConfig(
        maxConcurrent: wizardState.config.maxConcurrentAgents,
        agentTimeout:
            Duration(minutes: wizardState.config.agentTimeoutMinutes),
        claudeModel: wizardState.config.claudeModel,
        maxTurns: wizardState.config.maxTurns,
      );

      // Listen for the job created event to get the job ID.
      String? jobId;
      final subscription = orchestrator.lifecycleStream.listen((event) {
        if (event is JobCreated) {
          jobId = event.jobId;
        }
      });

      // Fire-and-forget the job execution.
      orchestrator.executeJob(
        projectId: project.id,
        projectName: project.name,
        projectPath: project.repoFullName ?? project.name,
        teamId: project.teamId,
        branch: wizardState.selectedBranch ?? 'main',
        mode: JobMode.audit,
        selectedAgents: wizardState.selectedAgents.toList(),
        config: dispatchConfig,
        additionalContext: wizardState.config.additionalContext.isNotEmpty
            ? wizardState.config.additionalContext
            : null,
      );

      // Wait briefly for the JobCreated event.
      await Future.delayed(const Duration(seconds: 2));
      await subscription.cancel();

      if (mounted) {
        notifier.setLaunching(false);
        notifier.reset();

        if (jobId != null) {
          context.go('/jobs/$jobId');
        } else {
          // Fallback: navigate to history if we didn't get a job ID.
          context.go('/history');
        }
      }
    } catch (e) {
      if (mounted) {
        notifier.setLaunchError(e.toString());
        showToast(context,
            message: 'Failed to launch audit: $e', type: ToastType.error);
      }
    }
  }
}
