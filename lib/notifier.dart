// lib/notifier.dart
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'service.dart';

class RangesNotifier extends ChangeNotifier {
  final RangesService _service;
  List<TestCaseModel> _tests = [];
  String? _error;
  bool _loading = true;

  int selectedIndex = 0;
  double inputValue = double.nan;

  RangesNotifier(this._service);

  List<TestCaseModel> get tests => _tests;
  bool get isLoading => _loading;
  String? get error => _error;
  TestCaseModel? get selectedTest => _tests.isNotEmpty ? _tests[selectedIndex] : null;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.fetchTestCases();
      _tests = result;
      if (_tests.isEmpty) {
        _error = 'No test cases received';
      } else {
        final t = _tests[selectedIndex];
        inputValue = (t.min + t.max) / 2;
      }
    } catch (e) {
      _error = 'Failed to load ranges:\n${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectTest(int index) {
    if (index < 0 || index >= _tests.length) return;
    selectedIndex = index;
    final t = _tests[selectedIndex];
    inputValue = (t.min + t.max) / 2;
    notifyListeners();
  }

  void updateInput(double? value) {
    if (value == null) {
      inputValue = double.nan;
    } else {
      inputValue = value;
    }
    notifyListeners();
  }

  void retry() {
    load();
  }
}
