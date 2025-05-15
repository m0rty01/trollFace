import 'dart:math';
import 'package:flutter/material.dart';
import '../services/face_filter_service.dart';
import '../models/face_filter.dart';

class FaceFilterRenderer extends StatelessWidget {
  final FaceFilterService faceFilterService;
  final List<FaceFilter> filters;
  final Size size;
  final bool isMirrored;

  const FaceFilterRenderer({
    Key? key,
    required this.faceFilterService,
    required this.filters,
    required this.size,
    this.isMirrored = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _FilterPainter(
        filters: filters,
        isMirrored: isMirrored,
      ),
    );
  }
}

class _FilterPainter extends CustomPainter {
  final List<FaceFilter> filters;
  final bool isMirrored;

  _FilterPainter({
    required this.filters,
    required this.isMirrored,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final filter in filters) {
      if (filter.image != null) {
        final paint = Paint()
          ..colorFilter = _createColorFilter(filter.style)
          ..filterQuality = FilterQuality.high;

        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.save();
        
        if (filter.rotation != 0) {
          canvas.rotate(filter.rotation * pi / 180);
        }
        
        if (filter.scale != 1.0) {
          canvas.scale(filter.scale);
        }
        
        // TODO: Properly load and draw the image as a dart:ui.Image
        // canvas.drawImage(
        //   Image.asset(filter.image!),
        //   Offset.zero,
        //   paint,
        // );
        // Placeholder: draw a colored rectangle
        canvas.drawRect(
          Rect.fromLTWH(0, 0, 100, 100),
          paint..color = Colors.blue.withOpacity(0.3),
        );
        
        canvas.restore();
      }
    }
  }

  ColorFilter _createColorFilter(FilterStyle style) {
    final filters = <ColorFilter>[];
    
    if (style.brightness != 0) {
      filters.add(ColorFilter.matrix([
        1, 0, 0, 0, style.brightness,
        0, 1, 0, 0, style.brightness,
        0, 0, 1, 0, style.brightness,
        0, 0, 0, 1, 0,
      ]));
    }
    
    if (style.contrast != 1) {
      final factor = (259 * (style.contrast + 255)) / (255 * (259 - style.contrast));
      filters.add(ColorFilter.matrix([
        factor, 0, 0, 0, 128 * (1 - factor),
        0, factor, 0, 0, 128 * (1 - factor),
        0, 0, factor, 0, 128 * (1 - factor),
        0, 0, 0, 1, 0,
      ]));
    }
    
    if (style.saturation != 1) {
      final r = 0.213;
      final g = 0.715;
      final b = 0.072;
      final s = style.saturation;
      
      filters.add(ColorFilter.matrix([
        (1 - s) * r + s, (1 - s) * r, (1 - s) * r, 0, 0,
        (1 - s) * g, (1 - s) * g + s, (1 - s) * g, 0, 0,
        (1 - s) * b, (1 - s) * b, (1 - s) * b + s, 0, 0,
        0, 0, 0, 1, 0,
      ]));
    }
    
    if (style.tint != Colors.transparent) {
      filters.add(ColorFilter.mode(style.tint, BlendMode.srcATop));
    }
    
    return filters.fold<ColorFilter>(
      const ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      (previous, filter) => ColorFilter.matrix(_combineColorMatrices(
        _matrixToList(previous),
        _matrixToList(filter),
      )),
    );
  }

  List<double> _matrixToList(ColorFilter filter) {
    // Convert ColorFilter to matrix values
    return List<double>.filled(20, 0);
  }

  List<double> _combineColorMatrices(List<double> a, List<double> b) {
    // Combine two color matrices
    return List<double>.filled(20, 0);
  }

  @override
  bool shouldRepaint(_FilterPainter oldDelegate) {
    return oldDelegate.filters != filters || oldDelegate.isMirrored != isMirrored;
  }
} 