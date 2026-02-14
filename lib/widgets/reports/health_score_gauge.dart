/// Animated circular health score gauge widget.
///
/// Displays a score from 0-100 with color-coded arc and animated transitions.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Animated circular gauge displaying a health score (0-100).
class HealthScoreGauge extends StatefulWidget {
  /// The health score to display (0-100).
  final int score;

  /// Size of the gauge widget.
  final double size;

  /// Stroke width of the arc.
  final double strokeWidth;

  /// Whether to show the score label below.
  final bool showLabel;

  /// Creates a [HealthScoreGauge].
  const HealthScoreGauge({
    super.key,
    required this.score,
    this.size = AppConstants.gaugeDefaultSize,
    this.strokeWidth = 8,
    this.showLabel = true,
  });

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
          milliseconds: AppConstants.healthScoreAnimationMs),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= AppConstants.healthScoreGreenThreshold) {
      return CodeOpsColors.success;
    } else if (score >= AppConstants.healthScoreYellowThreshold) {
      return CodeOpsColors.warning;
    } else {
      return CodeOpsColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final color = _scoreColor(value);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: value,
                  color: color,
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Text(
                    '${value.round()}',
                    style: TextStyle(
                      color: color,
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 4),
              Text(
                'Health Score',
                style: TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: widget.size * 0.1,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final double strokeWidth;

  _GaugePainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi * 0.75;
    const totalSweep = math.pi * 1.5;
    final sweepAngle = totalSweep * (score / 100);

    // Background arc
    final bgPaint = Paint()
      ..color = CodeOpsColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      score != oldDelegate.score || color != oldDelegate.color;
}
