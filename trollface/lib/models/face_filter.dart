import 'package:flutter/material.dart';
import 'dart:math' show atan2, pi, sqrt;
import 'dart:ui';

enum FilterCategory {
  accessories,
  facial,
  headwear,
  fun,
  seasonal,
  other,
}

class FilterPreset {
  final String name;
  final List<FaceFilter> filters;
  final String? icon;

  const FilterPreset({
    required this.name,
    required this.filters,
    this.icon,
  });

  static const List<FilterPreset> predefined = [
    FilterPreset(
      name: 'Classic',
      icon: '🎭',
      filters: [
        FaceFilter(
          name: 'Glasses',
          assetPath: 'assets/filters/glasses.png',
          landmarkIndices: [33, 263],
          baseScale: 1.2,
          offset: Offset(0, -0.1),
          category: FilterCategory.accessories,
          animation: FilterAnimation(
            startScale: 0.5,
            endScale: 1.2,
            startRotation: -0.2,
          ),
          isAnimated: true,
        ),
        FaceFilter(
          name: 'Mustache',
          assetPath: 'assets/filters/mustache.png',
          landmarkIndices: [61, 291],
          baseScale: 1.0,
          offset: Offset(0, 0.1),
          category: FilterCategory.facial,
          style: FilterStyle(
            tint: Color(0xFF8B4513),
            opacity: 0.9,
          ),
        ),
      ],
    ),
    FilterPreset(
      name: 'Royal',
      icon: '👑',
      filters: [
        FaceFilter(
          name: 'Crown',
          assetPath: 'assets/filters/crown.png',
          landmarkIndices: [10, 338],
          baseScale: 1.3,
          offset: Offset(0, -0.4),
          category: FilterCategory.headwear,
          style: FilterStyle(
            tint: Color(0xFFFFD700),
            brightness: 1.2,
          ),
          animation: FilterAnimation(
            startScale: 0.5,
            endScale: 1.3,
            startRotation: 0.1,
          ),
          isAnimated: true,
        ),
      ],
    ),
    FilterPreset(
      name: 'Mysterious',
      icon: '🎭',
      filters: [
        FaceFilter(
          name: 'Mask',
          assetPath: 'assets/filters/mask.png',
          landmarkIndices: [33, 263],
          baseScale: 1.1,
          offset: Offset.zero,
          category: FilterCategory.accessories,
          style: FilterStyle(
            opacity: 0.8,
            contrast: 1.2,
          ),
        ),
      ],
    ),
  ];
}

class FaceLandmark {
  final int index;
  final Offset position;

  FaceLandmark(this.index, this.position);

  factory FaceLandmark.fromJson(Map<String, dynamic> json) {
    return FaceLandmark(
      json['index'] as int,
      Offset(
        json['x'] as double,
        json['y'] as double,
      ),
    );
  }
}

class FilterStyle {
  final double opacity;
  final double brightness;
  final double contrast;
  final double saturation;
  final Color tint;

  const FilterStyle({
    this.opacity = 1.0,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.tint = Colors.transparent,
  });

  Map<String, dynamic> toMap() => {
    'opacity': opacity,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'tint': tint.value,
  };

  factory FilterStyle.fromMap(Map<String, dynamic> map) => FilterStyle(
    opacity: map['opacity']?.toDouble() ?? 1.0,
    brightness: map['brightness']?.toDouble() ?? 1.0,
    contrast: map['contrast']?.toDouble() ?? 1.0,
    saturation: map['saturation']?.toDouble() ?? 1.0,
    tint: map['tint'] != null ? Color(map['tint']) : Colors.transparent,
  );
}

class FilterAnimation {
  final double startScale;
  final double endScale;
  final double startRotation;
  final double endRotation;
  final double startOpacity;
  final double endOpacity;
  final bool loop;
  final bool reverse;
  final double duration;

  const FilterAnimation({
    this.startScale = 1.0,
    this.endScale = 1.0,
    this.startRotation = 0.0,
    this.endRotation = 0.0,
    this.startOpacity = 1.0,
    this.endOpacity = 1.0,
    this.loop = false,
    this.reverse = false,
    this.duration = 1.0,
  });

  Map<String, dynamic> toMap() => {
    'startScale': startScale,
    'endScale': endScale,
    'startRotation': startRotation,
    'endRotation': endRotation,
    'startOpacity': startOpacity,
    'endOpacity': endOpacity,
    'loop': loop,
    'reverse': reverse,
    'duration': duration,
  };

  factory FilterAnimation.fromMap(Map<String, dynamic> map) => FilterAnimation(
    startScale: map['startScale']?.toDouble() ?? 1.0,
    endScale: map['endScale']?.toDouble() ?? 1.0,
    startRotation: map['startRotation']?.toDouble() ?? 0.0,
    endRotation: map['endRotation']?.toDouble() ?? 0.0,
    startOpacity: map['startOpacity']?.toDouble() ?? 1.0,
    endOpacity: map['endOpacity']?.toDouble() ?? 1.0,
    loop: map['loop'] ?? false,
    reverse: map['reverse'] ?? false,
    duration: map['duration']?.toDouble() ?? 1.0,
  );
}

class FaceFilter {
  final String name;
  final String assetPath;
  final List<int> landmarkIndices;
  final double baseScale;
  final Offset offset;
  final double rotationOffset;
  final FilterStyle style;
  final FilterAnimation? animation;
  final bool isAnimated;
  final FilterCategory category;
  final List<String> tags;
  final Duration? autoRemoveAfter;
  final List<String> triggerEffects;

  const FaceFilter({
    required this.name,
    required this.assetPath,
    required this.landmarkIndices,
    this.baseScale = 1.0,
    this.offset = Offset.zero,
    this.rotationOffset = 0.0,
    this.style = const FilterStyle(),
    this.animation,
    this.isAnimated = false,
    this.category = FilterCategory.accessories,
    this.tags = const [],
    this.autoRemoveAfter,
    this.triggerEffects = const [],
  });

  FaceFilter copyWith({
    String? name,
    String? assetPath,
    List<int>? landmarkIndices,
    double? baseScale,
    Offset? offset,
    double? rotationOffset,
    FilterStyle? style,
    FilterAnimation? animation,
    bool? isAnimated,
    FilterCategory? category,
    List<String>? tags,
    Duration? autoRemoveAfter,
    List<String>? triggerEffects,
  }) {
    return FaceFilter(
      name: name ?? this.name,
      assetPath: assetPath ?? this.assetPath,
      landmarkIndices: landmarkIndices ?? this.landmarkIndices,
      baseScale: baseScale ?? this.baseScale,
      offset: offset ?? this.offset,
      rotationOffset: rotationOffset ?? this.rotationOffset,
      style: style ?? this.style,
      animation: animation ?? this.animation,
      isAnimated: isAnimated ?? this.isAnimated,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      autoRemoveAfter: autoRemoveAfter ?? this.autoRemoveAfter,
      triggerEffects: triggerEffects ?? this.triggerEffects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'assetPath': assetPath,
      'landmarkIndices': landmarkIndices,
      'baseScale': baseScale,
      'offset': '${offset.dx},${offset.dy}',
      'rotationOffset': rotationOffset,
      'style': style.toMap(),
      'animation': animation?.toMap(),
      'isAnimated': isAnimated,
      'category': category.toString(),
      'tags': tags,
      'autoRemoveAfter': autoRemoveAfter?.inSeconds,
      'triggerEffects': triggerEffects,
    };
  }

  factory FaceFilter.fromJson(Map<String, dynamic> json) {
    final offsetParts = (json['offset'] as String).split(',');
    return FaceFilter(
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      landmarkIndices: List<int>.from(json['landmarkIndices'] ?? []),
      baseScale: json['baseScale']?.toDouble() ?? 1.0,
      offset: Offset(
        double.parse(offsetParts[0]),
        double.parse(offsetParts[1]),
      ),
      rotationOffset: json['rotationOffset']?.toDouble() ?? 0.0,
      style: FilterStyle.fromMap(json['style'] ?? {}),
      animation: json['animation'] != null ? FilterAnimation.fromMap(json['animation'] as Map<String, dynamic>) : null,
      isAnimated: json['isAnimated'] as bool,
      category: FilterCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => FilterCategory.other,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      autoRemoveAfter: json['autoRemoveAfter'] != null ? Duration(seconds: json['autoRemoveAfter'] as int) : null,
      triggerEffects: List<String>.from(json['triggerEffects'] ?? []),
    );
  }

  // For renderer compatibility
  String? get image => assetPath;
  double get rotation => rotationOffset;
  double get scale => baseScale;

  static const List<FaceFilter> predefined = [
    FaceFilter(
      name: 'Glasses',
      assetPath: 'assets/filters/glasses.png',
      landmarkIndices: [33, 263],
      baseScale: 1.2,
      offset: Offset(0, -0.1),
      category: FilterCategory.accessories,
      tags: ['classic', 'formal'],
      animation: FilterAnimation(
        startScale: 0.5,
        endScale: 1.2,
        startRotation: -0.2,
      ),
      isAnimated: true,
    ),
    FaceFilter(
      name: 'Mustache',
      assetPath: 'assets/filters/mustache.png',
      landmarkIndices: [61, 291],
      baseScale: 1.0,
      offset: Offset(0, 0.1),
      category: FilterCategory.facial,
      tags: ['classic', 'funny'],
      style: FilterStyle(
        tint: Color(0xFF8B4513),
        opacity: 0.9,
      ),
    ),
    FaceFilter(
      name: 'Troll Face',
      assetPath: 'assets/filters/troll_face.png',
      landmarkIndices: [33, 263],
      baseScale: 1.1,
      offset: Offset.zero,
      category: FilterCategory.fun,
      tags: ['troll', 'funny'],
      style: FilterStyle(
        opacity: 0.9,
        contrast: 1.2,
      ),
      triggerEffects: ['onStart'],
      autoRemoveAfter: Duration(seconds: 5),
    ),
    FaceFilter(
      name: 'Hat',
      assetPath: 'assets/filters/hat.png',
      landmarkIndices: [10, 338],
      baseScale: 1.5,
      offset: Offset(0, -0.3),
      category: FilterCategory.headwear,
      tags: ['casual', 'summer'],
      animation: FilterAnimation(
        startScale: 0.3,
        endScale: 1.5,
        startOpacity: 0.0,
      ),
      isAnimated: true,
    ),
    FaceFilter(
      name: 'Crown',
      assetPath: 'assets/filters/crown.png',
      landmarkIndices: [10, 338],
      baseScale: 1.3,
      offset: Offset(0, -0.4),
      category: FilterCategory.headwear,
      tags: ['royal', 'special'],
      style: FilterStyle(
        tint: Color(0xFFFFD700),
        brightness: 1.2,
      ),
      animation: FilterAnimation(
        startScale: 0.5,
        endScale: 1.3,
        startRotation: 0.1,
      ),
      isAnimated: true,
    ),
    FaceFilter(
      name: 'Mask',
      assetPath: 'assets/filters/mask.png',
      landmarkIndices: [33, 263],
      baseScale: 1.1,
      offset: Offset.zero,
      category: FilterCategory.accessories,
      tags: ['mysterious', 'party'],
      style: FilterStyle(
        opacity: 0.8,
        contrast: 1.2,
      ),
    ),
    FaceFilter(
      name: 'Santa Hat',
      assetPath: 'assets/filters/santa_hat.png',
      landmarkIndices: [10, 338],
      baseScale: 1.4,
      offset: Offset(0, -0.35),
      category: FilterCategory.seasonal,
      tags: ['christmas', 'holiday'],
      style: FilterStyle(
        tint: Color(0xFFD32F2F),
        brightness: 1.1,
      ),
      animation: FilterAnimation(
        startScale: 0.4,
        endScale: 1.4,
        startRotation: -0.1,
        loop: true,
        reverse: true,
      ),
      isAnimated: true,
    ),
    FaceFilter(
      name: 'Party Hat',
      assetPath: 'assets/filters/party_hat.png',
      landmarkIndices: [10, 338],
      baseScale: 1.3,
      offset: Offset(0, -0.4),
      category: FilterCategory.fun,
      tags: ['party', 'celebration'],
      style: FilterStyle(
        tint: Color(0xFFFF4081),
        saturation: 1.2,
      ),
      animation: FilterAnimation(
        startScale: 0.5,
        endScale: 1.3,
        startRotation: 0.2,
        loop: true,
      ),
      isAnimated: true,
    ),
  ];
}

class FilterTransform {
  final Offset position;
  final double rotation;
  final double scale;
  final double opacity;
  final Color tint;
  final double brightness;
  final double contrast;
  final double saturation;

  FilterTransform({
    required this.position,
    required this.rotation,
    required this.scale,
    this.opacity = 1.0,
    this.tint = Colors.white,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  factory FilterTransform.fromLandmarks(
    List<FaceLandmark> landmarks,
    FaceFilter filter,
  ) {
    if (landmarks.length < 2) {
      return FilterTransform(
        position: Offset.zero,
        rotation: 0,
        scale: 1,
      );
    }

    // Calculate midpoint
    final midpoint = Offset(
      (landmarks[0].position.dx + landmarks[1].position.dx) / 2,
      (landmarks[0].position.dy + landmarks[1].position.dy) / 2,
    );

    // Calculate rotation
    final dx = landmarks[1].position.dx - landmarks[0].position.dx;
    final dy = landmarks[1].position.dy - landmarks[0].position.dy;
    final rotation = (atan2(dy, dx) * 180 / pi) + filter.rotationOffset;

    // Calculate scale based on distance between landmarks
    final distance = sqrt(dx * dx + dy * dy);
    final scale = (distance / 100) * filter.baseScale;

    // Apply offset
    final position = Offset(
      midpoint.dx + (filter.offset.dx * distance),
      midpoint.dy + (filter.offset.dy * distance),
    );

    return FilterTransform(
      position: position,
      rotation: rotation,
      scale: scale,
      opacity: filter.style.opacity,
      tint: filter.style.tint,
      brightness: filter.style.brightness,
      contrast: filter.style.contrast,
      saturation: filter.style.saturation,
    );
  }
} 