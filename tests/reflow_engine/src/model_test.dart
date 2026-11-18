import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('DocumentInput JSON', () {
    test('round-trips pages and characters', () {
      final input = DocumentInput(
        pages: [
          page(1, [line('Hi there')]),
        ],
      );

      final copy = DocumentInput.fromJson(input.toJson());

      expect(copy, input);
    });
  });

  group('ReflowDocument JSON', () {
    test('round-trips blocks with engine version', () {
      const doc = ReflowDocument(
        engineVersion: 7,
        blocks: [
          ReflowBlock(
            id: 'p1b0',
            type: BlockType.paragraph,
            text: 'Hello world',
            page: 1,
            box: BBox(1, 2, 3, 4),
          ),
        ],
      );

      final copy = ReflowDocument.fromJson(doc.toJson());

      expect(copy, doc);
    });
  });

  test('ReflowBlock JSON keeps the heading level and omits it if absent', () {
    const heading = ReflowBlock(
      id: 'p1b0',
      type: BlockType.heading,
      text: 'Intro',
      page: 1,
      box: BBox(0, 0, 1, 1),
      level: 2,
    );
    const figure = ReflowBlock(
      id: 'p1b1',
      type: BlockType.figure,
      text: '',
      page: 1,
      box: BBox(0, 2, 1, 3),
    );

    expect(ReflowBlock.fromJson(heading.toJson()), heading);
    expect(figure.toJson().containsKey('level'), isFalse);
    expect(ReflowBlock.fromJson(figure.toJson()), figure);
  });

  test('BBox union covers both boxes', () {
    expect(
      const BBox(0, 5, 10, 8).union(const BBox(4, 2, 12, 6)),
      const BBox(0, 2, 12, 8),
    );
  });
}
