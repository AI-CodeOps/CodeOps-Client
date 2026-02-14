/// Reusable multi-step wizard container.
///
/// Provides a left sidebar step indicator, main content area, and
/// bottom navigation bar with Back/Next/Launch buttons. Includes
/// a top bar with title and Cancel button (with confirm dialog).
/// Designed for reuse across Audit, Compliance, Bug Investigation,
/// and Remediation wizard modes.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../shared/confirm_dialog.dart';

/// Defines a single step in the wizard.
class WizardStepDef {
  /// Display title for the step.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Icon for the step indicator.
  final IconData icon;

  /// The widget to render for this step.
  final Widget content;

  /// Whether this step's validation passes.
  final bool isValid;

  /// Creates a [WizardStepDef].
  const WizardStepDef({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.content,
    this.isValid = true,
  });
}

/// A multi-step wizard scaffold with step indicator, content area, and nav bar.
class WizardScaffold extends StatelessWidget {
  /// The wizard title displayed in the top bar.
  final String title;

  /// The list of steps.
  final List<WizardStepDef> steps;

  /// The current step index.
  final int currentStep;

  /// Called when Back is pressed.
  final VoidCallback? onBack;

  /// Called when Next is pressed.
  final VoidCallback? onNext;

  /// Called when Launch is pressed (on the final step).
  final VoidCallback? onLaunch;

  /// Called when Cancel is confirmed.
  final VoidCallback? onCancel;

  /// Whether a launch is in progress.
  final bool isLaunching;

  /// Label for the final action button.
  final String launchLabel;

  /// Creates a [WizardScaffold].
  const WizardScaffold({
    super.key,
    required this.title,
    required this.steps,
    required this.currentStep,
    this.onBack,
    this.onNext,
    this.onLaunch,
    this.onCancel,
    this.isLaunching = false,
    this.launchLabel = 'Launch',
  });

  bool get _isFirstStep => currentStep == 0;
  bool get _isLastStep => currentStep == steps.length - 1;
  bool get _currentStepValid =>
      currentStep < steps.length && steps[currentStep].isValid;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        _TopBar(
          title: title,
          onCancel: onCancel != null
              ? () => _confirmCancel(context)
              : null,
        ),

        // Main content
        Expanded(
          child: Row(
            children: [
              // Left sidebar step indicator
              _StepSidebar(
                steps: steps,
                currentStep: currentStep,
              ),

              // Content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: currentStep < steps.length
                      ? steps[currentStep].content
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),

        // Bottom navigation
        _BottomNav(
          isFirstStep: _isFirstStep,
          isLastStep: _isLastStep,
          isValid: _currentStepValid,
          isLaunching: isLaunching,
          launchLabel: launchLabel,
          onBack: _isFirstStep ? null : onBack,
          onNext: _isLastStep ? null : (_currentStepValid ? onNext : null),
          onLaunch: _isLastStep && _currentStepValid ? onLaunch : null,
        ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Wizard',
      message: 'Are you sure you want to cancel? All progress will be lost.',
      confirmLabel: 'Cancel Wizard',
      destructive: true,
    );
    if (confirmed == true && onCancel != null) {
      onCancel!();
    }
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onCancel;

  const _TopBar({required this.title, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onCancel != null)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: CodeOpsColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepSidebar extends StatelessWidget {
  final List<WizardStepDef> steps;
  final int currentStep;

  const _StepSidebar({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          right: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _StepItem(
              step: steps[i],
              index: i,
              isActive: i == currentStep,
              isCompleted: i < currentStep,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final WizardStepDef step;
  final int index;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.step,
    required this.index,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color textColor;
    if (isActive) {
      iconColor = CodeOpsColors.primary;
      textColor = CodeOpsColors.textPrimary;
    } else if (isCompleted) {
      iconColor = CodeOpsColors.success;
      textColor = CodeOpsColors.textSecondary;
    } else {
      iconColor = CodeOpsColors.textTertiary;
      textColor = CodeOpsColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? CodeOpsColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? CodeOpsColors.success
                  : isActive
                      ? CodeOpsColors.primary
                      : Colors.transparent,
              border: Border.all(
                color: iconColor,
                width: isActive || isCompleted ? 0 : 1,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Icon(step.icon, size: 14, color: isActive ? Colors.white : iconColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (step.subtitle != null)
                  Text(
                    step.subtitle!,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isValid;
  final bool isLaunching;
  final String launchLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onLaunch;

  const _BottomNav({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isValid,
    required this.isLaunching,
    required this.launchLabel,
    this.onBack,
    this.onNext,
    this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          top: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (!isFirstStep)
            OutlinedButton.icon(
              onPressed: isLaunching ? null : onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CodeOpsColors.textSecondary,
                side: const BorderSide(color: CodeOpsColors.border),
              ),
            ),
          const Spacer(),

          // Next or Launch button
          if (isLastStep)
            FilledButton.icon(
              onPressed: isLaunching ? null : onLaunch,
              icon: isLaunching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rocket_launch, size: 16),
              label: Text(isLaunching ? 'Launching...' : launchLabel),
              style: FilledButton.styleFrom(
                backgroundColor: CodeOpsColors.primary,
              ),
            )
          else
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
              style: FilledButton.styleFrom(
                backgroundColor: CodeOpsColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
