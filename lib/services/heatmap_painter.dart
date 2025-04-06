import 'package:flutter/material.dart';
import '../models/heat_point.dart';
import 'dart:math';

class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;

  HeatmapPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in points) {
      final paint =
          Paint()
            ..color = Color.fromRGBO(
              p.color.red,
              p.color.green,
              p.color.blue,
              p.intensity.clamp(0.2, 1) / 3,
            )
            ..style = PaintingStyle.fill;

      double referenceZoom = 17.0; // nivelul de zoom de referință
      double baseRadius = 1.0; // raza de bază
      double intensityFactor =
          5.0; // factor de mărire în funcție de intensitate

      // Factorul de scalare: dacă zoom-ul e mai mic decât referința, cercul se micșorează, iar dacă e mai mare, se mărește.
      double scaleFactor = pow(2, p.zoompos - referenceZoom).toDouble();

      // Raza finală în pixeli:
      double radius =
          (baseRadius + p.intensity * intensityFactor) * scaleFactor;

      canvas.drawCircle(p.offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
