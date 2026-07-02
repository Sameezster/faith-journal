import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A short rule with a solid gold sparkle centered on it.
///
/// Used under the wordmark on the splash screen and under each onboarding
/// title. Tune [lineWidth], [sparkleSize] and [color] per use.
class SparkleDivider extends StatelessWidget {
  const SparkleDivider({
    super.key,
    this.lineWidth = 56,
    this.sparkleSize = 16,
    this.color = AppColors.gold,
  });

  final double lineWidth;
  final double sparkleSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: lineWidth, height: 1.5, color: color),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SparkleShape(size: sparkleSize, color: color),
        ),
        Container(width: lineWidth, height: 1.5, color: color),
      ],
    );
  }
}

/// A solid, filled 4-point sparkle (concave diamond).
///
/// Drawn by hand because Lucide's sparkle is outline-only.
class SparkleShape extends StatelessWidget {
  const SparkleShape({
    super.key,
    this.size = 18,
    this.color = AppColors.gold,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SparklePainter(color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    final r = size.width / 2;
    // How far the concave curve pulls toward the center (smaller = sharper).
    final inner = r * 0.16;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(c, c - r) // top point
      ..quadraticBezierTo(c + inner, c - inner, c + r, c) // → right
      ..quadraticBezierTo(c + inner, c + inner, c, c + r) // → bottom
      ..quadraticBezierTo(c - inner, c + inner, c - r, c) // → left
      ..quadraticBezierTo(c - inner, c - inner, c, c - r) // → top
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.color != color;
}
