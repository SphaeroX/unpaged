import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/pdf/pdfrx_adapter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// Keeps the engine fixtures (`tests/reflow_engine/fixtures/*.json`) in sync
/// with what the pdfrx adapter really extracts from the corpus PDFs.
///
/// After an intentional adapter change, regenerate with
/// `UPDATE_FIXTURES=1 flutter test tests/app/core/pdf/corpus_fixtures_test.dart`
/// and re-run the engine snapshot tests.
void main() {
  setUpAll(() => pdfrxInitialize(tmpPath: Directory.systemTemp.path));

  final update = Platform.environment['UPDATE_FIXTURES'] == '1';
  final pdfs =
      Directory('tests/reflow_engine/corpus')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.pdf'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('corpus is not empty', () => expect(pdfs, isNotEmpty));

  for (final pdf in pdfs) {
    final name = pdf.uri.pathSegments.last.replaceAll('.pdf', '');
    test('fixture for $name matches the adapter output', () async {
      final input = await PdfrxAdapter().extractText(pdf.path);
      final fixture = File('tests/reflow_engine/fixtures/$name.json');
      // Round through JSON so both sides use the same rounding.
      final actual = DocumentInput.fromJson(
        jsonDecode(jsonEncode(input.toJson())) as Map<String, dynamic>,
      );

      if (update) {
        fixture
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode(actual.toJson()));
      }

      expect(fixture.existsSync(), isTrue, reason: 'missing ${fixture.path}');
      final expected = DocumentInput.fromJson(
        jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(actual, expected);
    });
  }
}
