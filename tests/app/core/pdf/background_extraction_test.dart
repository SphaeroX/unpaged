import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/pdf/pdfrx_adapter.dart';

/// Spike result (Task 02): text extraction and the engine both work off the
/// main isolate, so the import pipeline can run in the background.
void main() {
  const pdf = 'tests/reflow_engine/corpus/synthetic_single_column.pdf';

  test('pdfrx text extraction works inside a spawned isolate', () async {
    final tmp = Directory.systemTemp.path;
    final pages = await Isolate.run(() async {
      await pdfrxInitialize(tmpPath: tmp);
      final input = await PdfrxAdapter().extractText(pdf);
      return input.pages.length;
    });

    expect(pages, 2);
  });

  test(
    'the reflow engine result can be computed in a spawned isolate',
    () async {
      await pdfrxInitialize(tmpPath: Directory.systemTemp.path);
      final input = await PdfrxAdapter().extractText(pdf);

      final doc = await Isolate.run(() => const ReflowEngine().reflow(input));

      expect(doc.blocks, hasLength(5));
    },
  );
}
