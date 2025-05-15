import 'dart:math';
import 'package:flutter/material.dart';
import '../models/face_filter.dart';

class FaceFilterRenderer extends StatelessWidget {
  final FaceFilter filter;
  final Size size;

  const FaceFilterRenderer({
    Key? key,
    required this.filter,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _FaceFilterPainter(filter),
    );
  }
}

class _FaceFilterPainter extends CustomPainter {
  final FaceFilter filter;

  _FaceFilterPainter(this.filter);

  @override
  void paint(Canvas canvas, Size size) {
    if (filter.image != null) {
      final image = Image.asset(filter.image!);
      if (image != null) {
        if (filter.rotation != 0) {
          canvas.rotate(filter.rotation * pi / 180);
        }
        if (filter.scale != 1.0) {
          canvas.scale(filter.scale);
        }
        canvas.drawImage(
          image,
          Offset.zero,
          Paint()
            ..colorFilter = ColorFilter.mode(
              filter.style.tint,
              BlendMode.srcATop,
            )
            ..color = Colors.white.withOpacity(filter.style.opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FaceFilterPainter oldDelegate) {
    return oldDelegate.filter != filter;
  }
} 