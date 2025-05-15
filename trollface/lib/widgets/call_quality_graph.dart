import 'package:flutter/material.dart';
import '../services/call_quality_service.dart';

class CallQualityGraph extends StatelessWidget {
  final List<CallQuality> qualityHistory;
  final double width;
  final double height;

  const CallQualityGraph({
    Key? key,
    required this.qualityHistory,
    this.width = 200,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: CallQualityPainter(qualityHistory),
      ),
    );
  }
}

class CallQualityPainter extends CustomPainter {
  final List<CallQuality> qualityHistory;

  CallQualityPainter(this.qualityHistory);

  @override
  void paint(Canvas canvas, Size size) {
    if (qualityHistory.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final points = <Offset>[];

    // Calculate points
    for (var i = 0; i < qualityHistory.length; i++) {
      final quality = qualityHistory[i];
      final x = (i / (qualityHistory.length - 1)) * size.width;
      final y = (1 - quality.score / 100) * size.height;
      points.add(Offset(x, y));
    }

    // Draw quality zones
    _drawQualityZones(canvas, size);

    // Draw the line
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw the line with gradient
    final gradient = LinearGradient(
      colors: [
        _getQualityColor(qualityHistory.last.score),
        _getQualityColor(qualityHistory.first.score),
      ],
    );

    paint.shader = gradient.createShader(Rect.fromPoints(
      points.first,
      points.last,
    ));

    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(
        point,
        2,
        Paint()..color = _getQualityColor(qualityHistory[points.indexOf(point)].score),
      );
    }
  }

  void _drawQualityZones(Canvas canvas, Size size) {
    final zonePaint = Paint()..style = PaintingStyle.fill;

    // Poor zone (0-60)
    zonePaint.color = Colors.red.withOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      zonePaint,
    );

    // Fair zone (60-80)
    zonePaint.color = Colors.orange.withOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.4),
      zonePaint,
    );

    // Good zone (80-100)
    zonePaint.color = Colors.green.withOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.2),
      zonePaint,
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(CallQualityPainter oldDelegate) {
    return oldDelegate.qualityHistory != qualityHistory;
  }
} 