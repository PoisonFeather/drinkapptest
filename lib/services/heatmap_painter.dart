import 'package:flutter/material.dart';
import '../models/heat_point.dart';

class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;

  HeatmapPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in points) {
      final paint =
          Paint()
            ..color = p.color.withOpacity(p.intensity.clamp(0.2, 1) / 3)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(p.offset, p.crowd + p.intensity * 1 / p.zoompos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
