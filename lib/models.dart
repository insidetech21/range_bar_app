// lib/models.dart
import 'package:flutter/material.dart';

class RangeSection {
  final double start;
  final double end;
  final String label;
  final Color color;

  RangeSection({
    required this.start,
    required this.end,
    required this.label,
    required this.color,
  });

  factory RangeSection.fromMap(Map<String, dynamic> m) {
    // parse range: "0-7"
    final rangeStr = m['range'] ?? '0-0';
    final parts = rangeStr.split('-');
    final start = double.tryParse(parts[0]) ?? 0;
    final end = double.tryParse(parts[1]) ?? start;

    final label = m['meaning'] ?? '';

    final colorStr = m['color'] ?? '#000000';
    final color = _parseHexColor(colorStr);

    return RangeSection(
      start: start,
      end: end,
      label: label,
      color: color,
    );
  }
}

class TestCaseModel {
  final double min;
  final double max;
  final List<RangeSection> sections;
  final String title;

  TestCaseModel({
    required this.min,
    required this.max,
    required this.sections,
    this.title = '',
  });
}

Color _parseHexColor(String hex) {
  var s = hex.replaceAll('#', '').trim();
  if (s.length == 3) {
    s = s.split('').map((c) => c + c).join();
  }
  if (s.length == 6) s = 'FF$s';
  int val = int.tryParse(s, radix: 16) ?? 0xFFFF0000;
  return Color(val);
}
