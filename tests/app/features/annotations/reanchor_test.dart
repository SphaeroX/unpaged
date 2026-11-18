import 'package:flutter_test/flutter_test.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/features/annotations/domain/reanchor.dart';

ReflowDocument _doc(List<(String, int, String)> blocks) => ReflowDocument(
  engineVersion: 4,
  blocks: [
    for (final (id, page, text) in blocks)
      ReflowBlock(
        id: id,
        type: BlockType.paragraph,
        text: text,
        page: page,
        box: const BBox(0, 0, 1, 1),
      ),
  ],
);

void main() {
  const anchor = Anchor(
    blockId: 'p1b1',
    start: 4,
    end: 9,
    quote: 'quick',
    prefix: 'The ',
    suffix: ' brown fox',
  );

  test('an unchanged document keeps the anchor', () {
    final doc = _doc([
      ('p1b0', 1, 'Intro.'),
      ('p1b1', 1, 'The quick brown fox.'),
    ]);

    expect(reanchor(doc, anchor), anchor);
  });

  test('moved block ids are found again via the quote', () {
    final doc = _doc([
      ('p1b0', 1, 'Intro.'),
      ('p1b1', 1, 'A new paragraph in front.'),
      ('p1b2', 1, 'The quick brown fox.'),
    ]);

    final result = reanchor(doc, anchor)!;

    expect(result.blockId, 'p1b2');
    expect(result.start, 4);
    expect(result.end, 9);
  });

  test('a changed line break inside the block is tolerated', () {
    final doc = _doc([('p1b0', 1, 'Intro. The quick brown fox.')]);

    final result = reanchor(doc, anchor)!;

    expect(result.blockId, 'p1b0');
    expect(doc.blocks.single.text.substring(result.start, result.end), 'quick');
  });

  test('the context decides between repeated quotes', () {
    final doc = _doc([
      ('p1b0', 1, 'A quick start guide.'),
      ('p1b1', 1, 'Others. The quick brown fox.'),
    ]);

    final result = reanchor(doc, anchor)!;

    expect(result.blockId, 'p1b1');
    expect(result.start, 12);
  });

  test('a quote that no longer exists is orphaned (null)', () {
    final doc = _doc([('p1b0', 1, 'Completely different text.')]);

    expect(reanchor(doc, anchor), isNull);
  });

  test('anchorFromSelection captures quote and context', () {
    final a = anchorFromSelection(
      blockId: 'p2b0',
      text: 'Some text before the chosen words and after.',
      start: 21,
      end: 33,
    );

    expect(a.quote, 'chosen words');
    expect(a.prefix, 'Some text before the ');
    expect(a.suffix, ' and after.');
  });
}
