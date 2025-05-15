import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/face_filter.dart';

class FilterPreferences {
  static const String _activeFiltersKey = 'active_filters';
  static const String _filterStylesKey = 'filter_styles';

  final SharedPreferences _prefs;

  FilterPreferences(this._prefs);

  Future<void> saveActiveFilters(List<FaceFilter> filters) async {
    final filterNames = filters.map((f) => f.name).toList();
    await _prefs.setStringList(_activeFiltersKey, filterNames);
  }

  List<String> getActiveFilterNames() {
    return _prefs.getStringList(_activeFiltersKey) ?? [];
  }

  Future<void> saveFilterStyle(String filterId, Map<String, dynamic> styleData) async {
    await _prefs.setString('filter_style_$filterId', styleData.toString());
  }

  Map<String, dynamic>? getFilterStyle(String filterId) {
    final styleDataStr = _prefs.getString('filter_style_$filterId');
    if (styleDataStr == null) return null;
    final styleData = jsonDecode(styleDataStr) as Map<String, dynamic>;
    return {
      'brightness': double.tryParse(styleData['brightness'].toString()) ?? 0.0,
      'contrast': double.tryParse(styleData['contrast'].toString()) ?? 1.0,
      'saturation': double.tryParse(styleData['saturation'].toString()) ?? 1.0,
      'tint': int.tryParse(styleData['tint'].toString()) ?? 0,
    };
  }

  Future<void> saveFilterCustomization(String filterId, FaceFilter filter) async {
    await _prefs.setString('filter_custom_$filterId', filter.toJson().toString());
  }

  FaceFilter? getFilterCustomization(String filterId) {
    final customData = _prefs.getString('filter_custom_$filterId');
    if (customData == null) return null;
    
    try {
      return FaceFilter.fromJson(Map<String, dynamic>.from(
        customData as Map<String, dynamic>
      ));
    } catch (e) {
      return null;
    }
  }

  Future<List<FaceFilter>> loadActiveFilters() async {
    final activeNames = getActiveFilterNames();
    final filters = <FaceFilter>[];

    for (final name in activeNames) {
      final predefinedFilter = FaceFilter.predefined.firstWhere(
        (f) => f.name == name,
        orElse: () => FaceFilter.predefined.first,
      );

      if (predefinedFilter != null) {
        final savedStyle = getFilterStyle(name);
        if (savedStyle != null) {
          filters.add(predefinedFilter.copyWith(style: FilterStyle.fromMap(savedStyle)));
        } else {
          filters.add(predefinedFilter);
        }
      }
    }

    return filters;
  }

  Future<void> clearPreferences() async {
    await _prefs.remove(_activeFiltersKey);
    await _prefs.remove(_filterStylesKey);
  }
} 