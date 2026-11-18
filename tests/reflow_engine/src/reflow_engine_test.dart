import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

List<String> paragraphs(DocumentInput input) =>
    const ReflowEngine().reflow(input).blocks.map((b) => b.text).toList();

void main() {
  group('ReflowEngine single column', () {
    test('joins consecutive lines into one paragraph', () {
      final input = DocumentInput(
        pages: [
          page(1, [
            line('The quick brown fox', y: 100),
            line('jumps over the dog.', y: 112),
          ]),
        ],
      );

      expect(paragraphs(input), ['The quick brown fox jumps over the dog.']);
    });

    test('starts a new paragraph after a larger vertical gap', () {
      final input = DocumentInput(
        pages: [
          page(1, [
            line('First paragraph line one', y: 100),
            line('first paragraph line two.', y: 112),
            line('Second paragraph line one', y: 136),
            line('second paragraph line two.', y: 148),
          ]),
        ],
      );

      expect(paragraphs(input), [
        'First paragraph line one first paragraph line two.',
        'Second paragraph line one second paragraph line two.',
      ]);
    });

    test('keeps double-spaced lines in one paragraph', () {
      final input = DocumentInput(
        pages: [
          page(1, [
            line('Double spaced text line one', y: 100),
            line('double spaced text line two', y: 128),
            line('double spaced text line three.', y: 156),
          ]),
        ],
      );

      expect(paragraphs(input), hasLength(1));
    });

    test('starts a new paragraph at a first-line indent', () {
      final input = DocumentInput(
        pages: [
          page(1, [
            line('Alpha alpha alpha alpha', y: 100),
            line('alpha alpha alpha alpha.', y: 112),
            line('Beta beta beta beta', x: 20, y: 124),
            line('beta beta beta beta beta.', y: 136),
          ]),
        ],
      );

      expect(paragraphs(input), hasLength(2));
    });

    test('starts a new paragraph when the font size changes', () {
      final input = DocumentInput(
        pages: [
          page(1, [
            line('A Heading', y: 100, size: 16),
            line('Body text follows here', y: 118),
            line('and continues here.', y: 130),
          ]),
        ],
      );

      expect(paragraphs(input), [
        'A Heading',
        'Body text follows here and continues here.',
      ]);
    });

    test('keeps pages apart and records the source page', () {
      final input = DocumentInput(
        pages: [
          page(1, [line('Page one text.', y: 100)]),
          page(2, [line('Page two text.', y: 100)]),
        ],
      );

      final blocks = const ReflowEngine().reflow(input).blocks;

      expect(blocks.map((b) => b.page), [1, 2]);
    });

    test('gives every block a stable, unique id', () {
      final input = DocumentInput(
        pages: [
          page(1, [line('One.', y: 100), line('Two.', y: 140)]),
          page(2, [line('Three.', y: 100)]),
        ],
      );

      final ids = const ReflowEngine().reflow(input).blocks.map((b) => b.id);

      expect(ids, ['p1b0', 'p1b1', 'p2b0']);
    });

    test('stamps the current engine version', () {
      final doc = const ReflowEngine().reflow(const DocumentInput(pages: []));

      expect(doc.engineVersion, ReflowEngine.version);
      expect(doc.blocks, isEmpty);
    });

    test('ignores pages without characters', () {
      final input = DocumentInput(
        pages: [
          page(1, const []),
          page(2, [line('Text.', y: 100)]),
        ],
      );

      expect(paragraphs(input), ['Text.']);
    });
  });
}
