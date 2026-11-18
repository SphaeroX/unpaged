import 'dart:convert';
import 'dart:io';

import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

DocumentInput loadFixture(String name) => DocumentInput.fromJson(
  jsonDecode(File('tests/reflow_engine/fixtures/$name.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test('synthetic single column yields exactly the known paragraphs', () {
    final doc = const ReflowEngine().reflow(
      loadFixture('synthetic_single_column'),
    );

    expect(doc.blocks.map((b) => (b.page, b.text)), [
      (
        1,
        'Reading long technical documents on a phone is tiring when the '
            'layout was made for paper. Small fonts, wide margins and fixed '
            'line breaks force the reader to zoom and pan all the time.',
      ),
      (
        1,
        'A reflow engine solves this by extracting the text and laying it '
            'out again for the screen. Each paragraph becomes a block that '
            'can wrap at any width, while the original page stays available '
            'for reference.',
      ),
      (
        1,
        'This synthetic document has three paragraphs on the first page and '
            'two on the second page. It exists so that tests can compare the '
            'engine output with a known, exact expectation.',
      ),
      (
        2,
        'The second page starts with a new paragraph. Its lines are wrapped '
            'by the generator at a fixed width, just like a typeset paper '
            'would be.',
      ),
      (2, 'The last paragraph is short.'),
    ]);
  });
}
