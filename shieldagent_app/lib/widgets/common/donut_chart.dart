import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DonutChart extends StatelessWidget {
  final double percentSpent; // 0-100
  final double size;
  final Color color;

  const DonutChart({
    super.key,
    required this.percentSpent,
    this.size = 140,
    this.color = AppColors.buyerAccent,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentSpent.clamp(0, 100).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _DonutPainter(percent: value, color: color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${clamped.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                "spent",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;
  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final track = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, track);

    final sweep = 6.2832 * (percent / 100);
    final progress = Paint()
      ..shader = SweepGradient(
        colors: [AppColors.primary, color],
        startAngle: 0,
        endAngle: sweep == 0 ? 0.001 : sweep,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, sweep, false, progress);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
