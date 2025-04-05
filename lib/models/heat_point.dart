import 'package:flutter/material.dart';

class HeatPoint {
  final Offset offset;
  final Color color;
  final double intensity;
  final double zoompos;
  final double crowd;

  HeatPoint(this.offset, this.color, this.intensity, this.zoompos, this.crowd);
}
