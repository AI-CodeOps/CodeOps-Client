/// Horizontal stepper showing the current job execution phase.
///
/// Renders 6 phase dots connected by lines. The active phase pulses
/// with a subtle animation. Completed phases are filled, future
/// phases are dimmed.
library;

import 'package:flutter/material.dart';

import '../../providers/wizard_providers.dart';
import '../../theme/colors.dart';

/// Displays a horizontal phase stepper for job execution progress.
class PhaseIndicator extends StatelessWidget {
  /// The current execution phase.
  final JobExecutionPhase currentPhase;

  /// Creates a [PhaseIndicator].
  const PhaseIndicator({super.key, required this.currentPhase});

  static const _phases = [
    JobExecutionPhase.creating,
    JobExecutionPhase.dispatching,
    JobExecutionPhase.running,
    JobExecutionPhase.consolidating,
    JobExecutionPhase.syncing,
    JobExecutionPhase.complete,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _phases.indexOf(currentPhase);
    final isFailed = currentPhase == JobExecutionPhase.failed;
    final isCancelled = currentPhase == JobExecutionPhase.cancelled;

    return Row(
      children: [
        for (var i = 0; i < _phases.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex && !isFailed && !isCancelled
                    ? CodeOpsColors.primary
                    : CodeOpsColors.border,
              ),
            ),
          _PhaseDot(
            label: _phases[i].displayName,
            isCompleted:
                i < currentIndex && !isFailed && !isCancelled,
            isActive:
                i == currentIndex && !isFailed && !isCancelled,
            isFailed: isFailed && i == currentIndex,
          ),
        ],
      ],
    );
  }
}

class _PhaseDot extends StatefulWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;
  final bool isFailed;

  const _PhaseDot({
    required this.label,
    required this.isCompleted,
    required this.isActive,
    required this.isFailed,
  });

  @override
  State<_PhaseDot> createState() => _PhaseDotState();
}

class _PhaseDotState extends State<_PhaseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PhaseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    if (widget.isFailed) {
      dotColor = CodeOpsColors.error;
    } else if (widget.isCompleted) {
      dotColor = CodeOpsColors.success;
    } else if (widget.isActive) {
      dotColor = CodeOpsColors.primary;
    } else {
      dotColor = CodeOpsColors.border;
    }

    return Tooltip(
      message: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (_, child) => Opacity(
              opacity: widget.isActive ? _animation.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: widget.isActive
                    ? Border.all(color: dotColor.withValues(alpha: 0.4), width: 3)
                    : null,
              ),
              child: widget.isCompleted
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              color: widget.isActive || widget.isCompleted
                  ? CodeOpsColors.textPrimary
                  : CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
