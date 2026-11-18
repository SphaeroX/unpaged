import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/features/progress/domain/reading_position.dart';
import 'package:reflow_engine/reflow_engine.dart';

ReflowBlock _b(String id, int page) => ReflowBlock(
  id: id,
  type: BlockType.paragraph,
  text: id,
  page: page,
  box: const BBox(0, 0, 1, 1),
);

void main() {
  // Page 2 holds only a figure page without text blocks in this document.
  final doc = ReflowDocument(
    engineVersion: 3,
    blocks: [_b('p1b0', 1), _b('p1b1', 1), _b('p3b0', 3), _b('p5b0', 5)],
  );

  group('blockIndexForPage', () {
    test('returns the first block of that page', () {
      expect(blockIndexForPage(doc, 3), 2);
      expect(blockIndexForPage(doc, 1), 0);
    });

    test('a page without blocks maps to the next block after it', () {
      expect(blockIndexForPage(doc, 2), 2);
      expect(blockIndexForPage(doc, 4), 3);
    });

    test('a page after the last block maps to the last block', () {
      expect(blockIndexForPage(doc, 9), 3);
    });

    test('an empty document maps to 0', () {
      expect(
        blockIndexForPage(
          const ReflowDocument(engineVersion: 3, blocks: []),
          4,
        ),
        0,
      );
    });
  });

  test('pageOfBlock returns the source page of a block', () {
    expect(pageOfBlock(doc, 3), 5);
  });

  group('resolveBlockIndex', () {
    test('uses the stored block id when it still exists', () {
      expect(resolveBlockIndex(doc, blockId: 'p3b0', page: 1), 2);
    });

    test('falls back to the stored page after a recomputation', () {
      expect(resolveBlockIndex(doc, blockId: 'gone', page: 5), 3);
    });
  });

  test('progress values', () {
    expect(originalProgress(page: 3, pageCount: 12), closeTo(0.25, 1e-9));
    expect(ebookProgress(index: 1, count: 4), closeTo(0.5, 1e-9));
    expect(ebookProgress(index: 0, count: 0), 0);
  });
}
