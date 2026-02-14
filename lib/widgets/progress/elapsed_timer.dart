/// A live elapsed-time display that ticks every second.
///
/// Shows elapsed time in HH:MM:SS format. Starts automatically on mount
/// and stops when disposed or when [running] is set to `false`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Displays a live-updating elapsed time counter.
class ElapsedTimer extends StatefulWidget {
  /// The start time from which elapsed time is calculated.
  final DateTime startTime;

  /// Whether the timer should be actively ticking.
  final bool running;

  /// Optional text style override.
  final TextStyle? style;

  /// Creates an [ElapsedTimer].
  const ElapsedTimer({
    super.key,
    required this.startTime,
    this.running = true,
    this.style,
  });

  @override
  State<ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<ElapsedTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    if (widget.running) _startTimer();
  }

  @override
  void didUpdateWidget(ElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !oldWidget.running) {
      _startTimer();
    } else if (!widget.running && oldWidget.running) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTime);
    });
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.running ? Icons.timer : Icons.timer_off,
          size: 16,
          color: CodeOpsColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          _formatElapsed(_elapsed),
          style: widget.style ??
              const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
