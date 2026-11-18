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

  test('synthetic two columns yield the known paragraphs in order', () {
    final doc = const ReflowEngine().reflow(
      loadFixture('synthetic_two_column'),
    );

    expect(doc.blocks.map((b) => (b.page, b.text)), [
      (1, 'A Synthetic Two Column Paper'),
      (
        1,
        'Reflow engines read the glyphs of a page and rebuild the text in '
            'reading order. This paper is laid out in two columns, so the left '
            'column must be read completely before the right one. Long words '
            'are split with an information hyphen at the end of a line, while '
            'a well-known compound keeps its hyphen even when the line ends '
            'after the Offline-Modus prefix in German text.',
      ),
      (
        1,
        'A second paragraph starts with an indent and continues on the next '
            'page without a break in the middle of the sentence. The '
            'well-known example above shows the rule.',
      ),
      (2, 'The final paragraph is short.'),
    ]);
  });

  group('corpus regressions', () {
    String fullText(String name) => const ReflowEngine()
        .reflow(loadFixture(name))
        .blocks
        .map((b) => b.text)
        .join('\n');

    test('superscript citations stay inside their line', () {
      expect(
        fullText('two_column_figures'),
        contains('deep ultraviolet (UV).1–3 For x'),
      );
    });

    test('degree signs stay attached to their number', () {
      expect(fullText('single_column_text'), contains('120° corners'));
    });
  });
}
