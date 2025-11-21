// lib/service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'models.dart';

class RangesService {
  final Uri endpoint =
  Uri.parse('https://nd-assignment.azurewebsites.net/api/get-ranges');

  // Bearer token from the assignment PDF
  final String bearerToken =
      'eb3dae0a10614a7e719277e07e268b12aeb3af6d7a4655472608451b321f5a95';

  /// Fetches test cases from the remote API.
  ///
  /// The API may return different shapes:
  /// - A flat List of range objects (observed shape: [{ "range": "0-7", "meaning": "...", "color": "#hex" }, ...])
  /// - A wrapped object containing `data` or `testCases`
  /// - A list of test-case objects (each with `ranges` / `sections`)
  ///
  /// This method is defensive and returns a List<TestCaseModel> in all cases.
  Future<List<TestCaseModel>> fetchTestCases() async {
    final httpClient = HttpClient();

    try {
      final request = await httpClient.getUrl(endpoint);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (kDebugMode) {
        // Print the raw body for debugging (you already used this to inspect the API)
        print('API body: $body');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }

      final data = jsonDecode(body);

      // -------------------------------------------------------------------
      // CASE A: API returns a flat list of range entries (your observed response)
      // Each entry looks like: { "range": "0-7", "meaning": "Caution", "color": "#5470a7" }
      // We convert that into one TestCaseModel containing multiple RangeSection.
      // -------------------------------------------------------------------
      if (data is List) {
        final sections = data.map<RangeSection>((e) {
          if (e is Map) {
            return RangeSection.fromMap(Map<String, dynamic>.from(e));
          }
          throw FormatException('Expected map entries inside ranges list');
        }).toList();

        if (sections.isEmpty) {
          // No sections -> return a default empty test case
          return [
            TestCaseModel(min: 0, max: 100, sections: [], title: 'Default Test')
          ];
        }

        final minVal =
        sections.map((s) => s.start).reduce((a, b) => a < b ? a : b);
        final maxVal =
        sections.map((s) => s.end).reduce((a, b) => a > b ? a : b);

        return [
          TestCaseModel(min: minVal, max: maxVal, sections: sections, title: 'Default Test')
        ];
      }

      // -------------------------------------------------------------------
      // CASE B: API returns an object. It may wrap a list in 'data' or 'testCases',
      // or directly contain a list of test-case objects (each with ranges/sections).
      // -------------------------------------------------------------------
      if (data is Map) {
        // Try common keys that might hold an array of test-cases
        final possibleLists = (data['data'] ?? data['testCases'] ?? data['cases'] ?? null);

        if (possibleLists is List) {
          // Parse each test-case object in that list
          return possibleLists.map<TestCaseModel>((entry) {
            if (entry is Map<String, dynamic>) {
              return _parseTestCaseFromMap(entry);
            } else {
              throw FormatException('Unexpected test-case entry format');
            }
          }).toList();
        }

        // If no top-level list found, maybe data itself contains ranges / sections
        // e.g. { "ranges": [ ... ], "min": 0, "max": 100, "title": "..." }
        return [_parseTestCaseFromMap(Map<String, dynamic>.from(data))];
      }

      // -------------------------------------------------------------------
      // Fallback: unknown shape -> return an empty default TestCaseModel
      // -------------------------------------------------------------------
      return [
        TestCaseModel(min: 0, max: 100, sections: [], title: 'Default Test')
      ];
    } finally {
      // Always close the client to avoid resource leaks
      httpClient.close(force: true);
    }
  }

  // Helper: parse a single Map into a TestCaseModel (used for wrapped shapes)
  TestCaseModel _parseTestCaseFromMap(Map<String, dynamic> e) {
    double parseDouble(dynamic v) {
      if (v == null) return double.nan;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? double.nan;
    }

    // The sections may be under different keys
    final sectionsRaw = (e['ranges'] ?? e['sections'] ?? e['data'] ?? e['rangeList']) ?? [];

    final List<RangeSection> sections = (sectionsRaw as List)
        .map((s) {
      if (s is Map) return RangeSection.fromMap(Map<String, dynamic>.from(s));
      throw FormatException('Expected map in sections list');
    })
        .toList();

    // Try explicit min/max keys first; otherwise derive from sections
    double overallMin = parseDouble(e['min'] ?? e['minValue']);
    double overallMax = parseDouble(e['max'] ?? e['maxValue']);

    if (overallMin.isNaN || overallMax.isNaN || overallMin >= overallMax) {
      if (sections.isNotEmpty) {
        overallMin = sections.map((s) => s.start).fold<double>(double.infinity, (a, b) => a < b ? a : b);
        overallMax = sections.map((s) => s.end).fold<double>(-double.infinity, (a, b) => a > b ? a : b);
      } else {
        overallMin = 0;
        overallMax = 100;
      }
    }

    final title = (e['title'] ?? e['name'] ?? '').toString();

    return TestCaseModel(min: overallMin, max: overallMax, sections: sections, title: title);
  }
}
