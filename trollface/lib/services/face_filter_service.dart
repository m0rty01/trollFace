import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/face_filter.dart';

class FaceFilterService {
  static final FaceFilterService _instance = FaceFilterService._internal();
  factory FaceFilterService() => _instance;
  FaceFilterService._internal();

  final Map<String, ui.Image> _filterImages = {};
  final List<FaceFilter> _activeFilters = [];

  List<FaceFilter> get activeFilters => List.unmodifiable(_activeFilters);

  Future<void> loadFilterImage(String assetPath) async {
    if (_filterImages.containsKey(assetPath)) return;

    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _filterImages[assetPath] = frame.image;
  }

  ui.Image? getFilterImage(String assetPath) => _filterImages[assetPath];

  void setActiveFilters(List<FaceFilter> filters) {
    _activeFilters.clear();
    _activeFilters.addAll(filters);
  }

  void addFilter(FaceFilter filter) {
    if (!_activeFilters.contains(filter)) {
      _activeFilters.add(filter);
    }
  }

  void removeFilter(FaceFilter filter) {
    _activeFilters.remove(filter);
  }

  void clearFilters() {
    _activeFilters.clear();
  }

  void dispose() {
    for (final image in _filterImages.values) {
      image.dispose();
    }
    _filterImages.clear();
    _activeFilters.clear();
  }
} 