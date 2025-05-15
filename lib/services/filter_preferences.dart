import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/face_filter.dart';
import 'dart:convert';

class FilterPreferences {
  static const String _activeFiltersKey = 'active_filters';
  static const String _filterStylesKey = 'filter_styles';

  final SharedPreferences _prefs;

  FilterPreferences(this._prefs);

  Future<void> saveActiveFilters(List<FaceFilter> filters) async {
    final filterIds = filters.map((f) => f.id).toList();
    await _prefs.setStringList(_activeFiltersKey, filterIds);
  }

  List<String> getActiveFilterIds() {
    return _prefs.getStringList(_activeFiltersKey) ?? [];
  }

  Future<void> saveFilterStyle(String filterId, FilterStyle style) async {
    final styles = _getFilterStyles();
    styles[filterId] = jsonEncode(style.toMap());
    await _prefs.setString(_filterStylesKey, jsonEncode(styles));
  }

  FilterStyle? getFilterStyle(String filterId) {
    final styles = _getFilterStyles();
    if (styles.containsKey(filterId)) {
      final map = jsonDecode(styles[filterId]!);
      return FilterStyle.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }

  Map<String, String> _getFilterStyles() {
    final jsonStr = _prefs.getString(_filterStylesKey);
    if (jsonStr == null) return {};
    final decoded = jsonDecode(jsonStr);
    return Map<String, String>.from(decoded);
  }

  Future<List<FaceFilter>> loadActiveFilters(List<FaceFilter> allPredefined) async {
    final ids = getActiveFilterIds();
    final List<FaceFilter> filters = [];
    for (final id in ids) {
      final predefined = allPredefined.firstWhere((f) => f.id == id, orElse: () => allPredefined.first);
      final style = getFilterStyle(id);
      filters.add(predefined.copyWith(style: style ?? predefined.style));
    }
    return filters;
  }

  Future<void> clearPreferences() async {
    await _prefs.remove(_activeFiltersKey);
    await _prefs.remove(_filterStylesKey);
  }
} 