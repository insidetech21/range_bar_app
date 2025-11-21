// test/parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models.dart';
import 'package:flutter/material.dart';

void main() {
  test('RangeSection.fromMap parses numeric and hex color', () {
    final m = {
      'from': 0,
      'to': 10,
      'label': 'Low',
      'color': '#00FF00',
    };

    final s = RangeSection.fromMap(m);
    expect(s.start, 0);
    expect(s.end, 10);
    expect(s.label, 'Low');
    expect(s.color.alpha, 255);
  });

  test('TestCaseModel min/max fallback', () {
    final sections = [
      RangeSection(start: 1, end: 5, label: 'A', color: Color(0xFF0000FF)),
      RangeSection(start: 5, end: 10, label: 'B', color: Color(0xFFFF0000)),
    ];

    final t = TestCaseModel(min: 1, max: 10, sections: sections);
    expect(t.min, lessThan(t.max));
    expect(t.sections.length, 2);
  });
}
