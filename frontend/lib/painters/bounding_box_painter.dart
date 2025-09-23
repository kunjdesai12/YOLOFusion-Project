import 'package:flutter/material.dart';
import 'dart:math' as math;

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size imageSize;
  final Size screenSize;

  BoundingBoxPainter(this.detections, this.imageSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var detection in detections) {
      final color = detection['color'] as List<int>?;
      if (color != null && color.length == 3) {
        paint.color = Color.fromRGBO(color[0], color[1], color[2], 1.0);
      } else {
        paint.color = Colors.green; // Fallback color
      }

      // Scale coordinates
      double scaleX = screenSize.width / imageSize.width;
      double scaleY = screenSize.height / imageSize.height;
      double scaledX1 = detection['x1'] * scaleX;
      double scaledY1 = detection['y1'] * scaleY;
      double scaledX2 = detection['x2'] * scaleX;
      double scaledY2 = detection['y2'] * scaleY;

      // Draw rectangle
      canvas.drawRect(
        Rect.fromLTRB(scaledX1, scaledY1, scaledX2, scaledY2),
        paint,
      );

      // Draw label and confidence (above the box)
      final textSpan = TextSpan(
        text: '${detection['label']} (${detection['conf'].toStringAsFixed(2)})',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2.0, color: Colors.black)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledX1, scaledY1 - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}