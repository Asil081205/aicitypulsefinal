import 'dart:math';
import 'package:flutter/material.dart';

// Custom Line Chart
class CustomLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double height;
  final Color lineColor;
  final bool showGrid;
  final bool showPoints;

  const CustomLineChart({
    super.key,
    required this.data,
    this.height = 200,
    this.lineColor = Colors.cyan,
    this.showGrid = true,
    this.showPoints = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CustomLineChartPainter(
          data: data,
          lineColor: lineColor,
          showGrid: showGrid,
          showPoints: showPoints,
        ),
      ),
    );
  }
}

// Custom Bar Chart
class CustomBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double height;
  final Map<String, Color> barColors;

  const CustomBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.barColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CustomBarChartPainter(
          data: data,
          barColors: barColors,
        ),
      ),
    );
  }
}

// Line Chart Painter
class _CustomLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final bool showGrid;
  final bool showPoints;

  _CustomLineChartPainter({
    required this.data,
    required this.lineColor,
    required this.showGrid,
    required this.showPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Calculate points
    final List<Offset> points = [];
    final double xStep = size.width / (data.length - 1);
    final maxValue = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b) * 1.1;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i]['value'] as double) / maxValue * size.height);
      points.add(Offset(x, y));
    }

    // Draw filled area
    final path = Path();
    path.moveTo(0, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    if (showPoints) {
      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
        canvas.drawCircle(point, 2, paint);
      }
    }

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 1;

      // Horizontal lines
      for (int i = 1; i <= 5; i++) {
        final y = size.height * i / 5;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Vertical lines
      for (int i = 0; i < data.length; i++) {
        final x = i * xStep;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Bar Chart Painter
class _CustomBarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final Map<String, Color> barColors;

  _CustomBarChartPainter({
    required this.data,
    required this.barColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / data.length * 0.6;
    final spacing = size.width / data.length * 0.4;

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final barHeight = (entry.value / maxValue) * size.height * 0.8;
      final x = i * (barWidth + spacing) + spacing / 2;
      final y = size.height - barHeight;

      final paint = Paint()
        ..color = barColors[entry.key] ?? Colors.cyan
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        paint,
      );

      // Draw label
      final textSpan = TextSpan(
        text: entry.key.substring(0, 3),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + barWidth / 2 - textPainter.width / 2, size.height + 5));

      // Draw value
      final valueSpan = TextSpan(
        text: entry.value.toStringAsFixed(0),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      final valuePainter = TextPainter(
        text: valueSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(canvas, Offset(x + barWidth / 2 - valuePainter.width / 2, y - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}