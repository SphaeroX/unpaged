import 'dart:convert';
import 'dart:io';

import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import 'corpus_test.dart' show loadFixture;

/// Corpus documents whose engine output is pinned by a snapshot.
///
/// Add a document only once the engine handles its layout. Snapshots are
/// never regenerated just to make a test pass (see docs/testing.md). To
/// create a missing snapshot: `UPDATE_SNAPSHOTS=1 flutter test
/// tests/reflow_engine/snapshot_test.dart`, then review the JSON by hand.
const snapshotDocuments = [
  'synthetic_single_column',
  'synthetic_two_column',
  'single_column_text',
  'two_column_tables',
  'two_column_formulas',
  'two_column_figures',
  'single_column_tables',
];

void main() {
  final update = Platform.environment['UPDATE_SNAPSHOTS'] == '1';
  const encoder = JsonEncoder.withIndent('  ');

  for (final name in snapshotDocuments) {
    test('snapshot of $name', () {
      final actual = const ReflowEngine().reflow(loadFixture(name));
      final file = File('tests/reflow_engine/snapshots/$name.json');

      if (update && !file.existsSync()) {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync('${encoder.convert(actual.toJson())}\n');
      }

      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
      final expected = ReflowDocument.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(
        encoder.convert(actual.toJson()),
        encoder.convert(expected.toJson()),
      );
    });
  }
}
