// test/notifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/notifier.dart';
import '../lib/service.dart';
import '../lib/models.dart';
import 'package:flutter/material.dart';

class FakeService extends RangesService {
  @override
  Future<List<TestCaseModel>> fetchTestCases() async {
    return [
      TestCaseModel(min: 0, max: 100, sections: [RangeSection(start: 0, end: 50, label: 'low', color: Color(0xFF00FF00))]),
    ];
  }
}

void main() {
  test('RangesNotifier loads and updates input', () async {
    final notifier = RangesNotifier(FakeService());
    await notifier.load();

    expect(notifier.isLoading, false);
    expect(notifier.tests.length, 1);
    expect(notifier.inputValue, isNotNull);

    notifier.updateInput(42);
    expect(notifier.inputValue, 42);

    notifier.selectTest(0);
    expect(notifier.selectedTest, isNotNull);
  });
}
