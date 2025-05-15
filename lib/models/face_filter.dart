import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FilterStyle {
  final double brightness;
  final double contrast;
  final double saturation;
  final double opacity;
  final Color tint;

  const FilterStyle({
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.opacity = 1.0,
    this.tint = Colors.transparent,
  });

  FilterStyle copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? opacity,
    Color? tint,
  }) {
    return FilterStyle(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      opacity: opacity ?? this.opacity,
      tint: tint ?? this.tint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'opacity': opacity,
      'tint': tint.value,
    };
  }

  factory FilterStyle.fromMap(Map<String, dynamic> map) {
    return FilterStyle(
      brightness: (map['brightness'] ?? 1.0).toDouble(),
      contrast: (map['contrast'] ?? 1.0).toDouble(),
      saturation: (map['saturation'] ?? 1.0).toDouble(),
      opacity: (map['opacity'] ?? 1.0).toDouble(),
      tint: Color(map['tint'] ?? Colors.transparent.value),
    );
  }

  String toJson() => toMap().toString();
  factory FilterStyle.fromJson(Map<String, dynamic> json) => FilterStyle.fromMap(json);
}

class FaceFilter {
  final String id;
  final String name;
  final FilterStyle style;
  final ui.Image? image;
  final double rotation;
  final double scale;
  final List<String> triggerEffects;

  const FaceFilter({
    required this.id,
    required this.name,
    required this.style,
    this.image,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.triggerEffects = const [],
  });

  FaceFilter copyWith({
    String? id,
    String? name,
    FilterStyle? style,
    ui.Image? image,
    double? rotation,
    double? scale,
    List<String>? triggerEffects,
  }) {
    return FaceFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      image: image ?? this.image,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      triggerEffects: triggerEffects ?? this.triggerEffects,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'style': style.toMap(),
      'rotation': rotation,
      'scale': scale,
      'triggerEffects': triggerEffects,
    };
  }

  factory FaceFilter.fromMap(Map<String, dynamic> map) {
    return FaceFilter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      style: FilterStyle.fromMap(Map<String, dynamic>.from(map['style'] ?? {})),
      rotation: (map['rotation'] ?? 0.0).toDouble(),
      scale: (map['scale'] ?? 1.0).toDouble(),
      triggerEffects: List<String>.from(map['triggerEffects'] ?? []),
      image: null, // image is not serialized
    );
  }

  String toJson() => toMap().toString();
  factory FaceFilter.fromJson(Map<String, dynamic> json) => FaceFilter.fromMap(json);
} 