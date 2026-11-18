import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

List<ReflowBlock> reflow(List<List<TextChar>> lines) =>
    const ReflowEngine().reflow(DocumentInput(pages: [page(1, lines)])).blocks;

List<(BlockType, String)> typed(List<List<TextChar>> lines) => [
  for (final b in reflow(lines)) (b.type, b.text),
];

/// Ten lines of ordinary prose so that the body font size is known.
List<List<TextChar>> prose({double y = 400, int lines = 4}) => [
  for (var i = 0; i < lines; i++)
    line(
      i == lines - 1
          ? 'and this sentence ends the paragraph here.'
          : 'this is ordinary body text with several words',
      y: y + 12.0 * i,
    ),
];

void main() {
  group('headings', () {
    test('a short line in a larger font is a heading', () {
      final blocks = reflow([
        line('Results', y: 100, size: 16),
        ...prose(y: 130),
      ]);

      expect(blocks.first.type, BlockType.heading);
      expect(blocks.first.text, 'Results');
      expect(blocks[1].type, BlockType.paragraph);
    });

    test('larger fonts get higher heading levels', () {
      final blocks = reflow([
        line('Document Title', y: 60, size: 20),
        line('Section', y: 100, size: 14),
        ...prose(y: 130),
      ]);

      expect(blocks[0].level, 1);
      expect(blocks[1].level, 2);
    });

    test('numbered headings in body size get their depth as level', () {
      final blocks = reflow([
        line('1 Introduction', y: 100),
        ...prose(y: 124),
        line('2.1 Spaces and bounds', y: 200),
        ...prose(y: 224),
      ]);

      expect(blocks[0].type, BlockType.heading);
      expect(blocks[0].level, 2);
      expect(blocks[2].type, BlockType.heading);
      expect(blocks[2].level, 3);
    });

    test('a well-known section word alone is a heading', () {
      expect(typed([line('Abstract', y: 100), ...prose(y: 124)]).first, (
        BlockType.heading,
        'Abstract',
      ));
    });

    test('a title wrapped over two lines is one heading', () {
      final blocks = reflow([
        line('A Long Document Title That Needs', y: 60, size: 16),
        line('Two Lines', y: 80, size: 16),
        ...prose(y: 120),
      ]);

      expect(blocks.first.type, BlockType.heading);
      expect(blocks.first.text, 'A Long Document Title That Needs Two Lines');
    });

    test('a three-line title with an all-caps line is one heading', () {
      final blocks = reflow([
        line('Measure Before You Train: Typed', y: 60, size: 16.5),
        line('LLM', y: 82, size: 16.5),
        line('for Routing a Personal Inbox', y: 104, size: 16.5),
        ...prose(y: 150),
      ]);

      expect(blocks.first.type, BlockType.heading);
      expect(
        blocks.first.text,
        'Measure Before You Train: Typed LLM for Routing a Personal Inbox',
      );
    });

    test('centered title lines are not mistaken for an indent', () {
      final blocks = reflow([
        line('A Centered Title Across The Page', x: 150, y: 60, size: 16),
        line('Second Line', x: 226, y: 82, size: 16),
        ...prose(y: 130),
      ]);

      expect(blocks.first.text, 'A Centered Title Across The Page Second Line');
    });

    test('an equation number in tall parentheses is not a heading', () {
      final result = typed([
        ...prose(y: 60),
        line('(1)', x: 400, y: 118, size: 13),
        ...prose(y: 140),
      ]);

      expect(result.map((t) => t.$1), isNot(contains(BlockType.heading)));
    });

    test('a long sentence in body size is not a heading', () {
      expect(typed(prose(y: 100)).map((t) => t.$1), [BlockType.paragraph]);
    });
  });

  group('lists', () {
    test('bullet items become list items, hanging lines stay inside', () {
      final result = typed([
        ...prose(y: 60),
        line('• First item that is long enough to', y: 124),
        line('wrap onto a second line.', x: 10, y: 136),
        line('• Second item.', y: 148),
      ]);

      expect(result.skip(1), [
        (
          BlockType.listItem,
          '• First item that is long enough to wrap onto a second line.',
        ),
        (BlockType.listItem, '• Second item.'),
      ]);
    });

    test('numbered items with a hanging indent stay one item each', () {
      final result = typed([
        ...prose(y: 60),
        line('1. A measurement protocol for a production', y: 124),
        line('agent that yields ground truth.', x: 15, y: 136),
        line('2. A comparison of eleven systems.', y: 148),
      ]);

      expect(result.skip(1).map((t) => t.$1), [
        BlockType.listItem,
        BlockType.listItem,
      ]);
      expect(result[1].$2, endsWith('yields ground truth.'));
    });
  });

  group('captions', () {
    for (final caption in [
      'Figure 1: The pipeline.',
      'Fig. 2. Device structures.',
      'FIG. 3. Band diagram.',
      'Table 1. Results per field.',
      'Abb. 4: Aufbau.',
    ]) {
      test('"$caption" is a caption', () {
        final result = typed([
          ...prose(y: 60),
          line(caption, y: 140),
          ...prose(y: 170),
        ]);

        expect(result, contains((BlockType.caption, caption)));
      });
    }
  });

  group('caption continuation', () {
    test('"(b)" inside a multi-line caption does not start a list item', () {
      final result = typed([
        ...prose(y: 60),
        line('Figure 1. Device structures. (a) Device 1 with a thin', y: 300),
        line('(b) Simulated band diagram of Device 1.', y: 312),
        ...prose(y: 340),
      ]);

      expect(result.where((t) => t.$1 == BlockType.listItem), isEmpty);
      expect(
        result.firstWhere((t) => t.$1 == BlockType.caption).$2,
        endsWith('band diagram of Device 1.'),
      );
    });
  });

  group('figures', () {
    test('labels above a figure caption become one figure region', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('1.0', x: 40, y: 140),
        line('Device 1', x: 200, y: 150),
        line('0.5', x: 40, y: 180),
        line('0 100 200', x: 60, y: 230),
        line('Figure 1: Measured spectra.', y: 260),
        ...prose(y: 290),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.figure,
        BlockType.caption,
        BlockType.paragraph,
      ]);
      final figure = blocks[1];
      expect(figure.text, isEmpty);
      expect(figure.box.top, lessThanOrEqualTo(140));
      expect(figure.box.bottom, greaterThanOrEqualTo(237));
      expect(figure.box.bottom, lessThanOrEqualTo(260));
    });

    test('an empty area above a figure caption becomes the region', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Figure 2: A picture without text.', y: 300),
        ...prose(y: 330),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.figure,
        BlockType.caption,
        BlockType.paragraph,
      ]);
      expect(blocks[1].box.top, greaterThanOrEqualTo(103));
      expect(blocks[1].box.bottom, lessThanOrEqualTo(300));
    });

    // Side caption (Springer style): a narrow caption in the left margin,
    // the figure to its right, starting at the caption's top.
    List<List<TextChar>> sideCaptionPage({required bool proseBelow}) => [
      ...prose(y: 60, lines: 3).take(2),
      line('this is ordinary body text with several words', y: 84),
      line('take place (Fig. 1.3).', y: 96),
      line('Fig. 1.3 Scheme of', y: 150, size: 8),
      line('formation', y: 160, size: 8),
      line('Pore', x: 190, y: 185, size: 7),
      line('Oxidized particle', x: 190, y: 200, size: 7),
      line('Substrate', x: 190, y: 245, size: 7),
      if (proseBelow) ...prose(y: 340),
    ];

    for (final proseBelow in [true, false]) {
      test('a side caption puts the figure to its right '
          '(prose below: $proseBelow)', () {
        final blocks = reflow(sideCaptionPage(proseBelow: proseBelow));

        expect(
          blocks.first.text,
          endsWith('take place (Fig. 1.3).'),
          reason: 'the short last line of a paragraph is no figure label',
        );
        final caption = blocks.singleWhere((b) => b.type == BlockType.caption);
        expect(caption.text, 'Fig. 1.3 Scheme of formation');
        final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
        expect(figure.box.left, greaterThanOrEqualTo(caption.box.right));
        expect(figure.box.left, lessThan(190));
        expect(figure.box.top, greaterThanOrEqualTo(103));
        expect(figure.box.top, lessThanOrEqualTo(150));
        expect(figure.box.bottom, greaterThan(250));
        if (proseBelow) expect(figure.box.bottom, lessThanOrEqualTo(340));
        expect(
          blocks.map((b) => b.text).join(' '),
          isNot(contains('Substrate')),
        );
      });
    }
  });

  group('tables', () {
    test('a grid of cells becomes a table region below its caption', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Table 1. Accuracy per field.', y: 130),
        for (var r = 0; r < 4; r++)
          for (var c = 0; c < 4; c++)
            line(
              r == 0 ? 'Head$c' : '0.$r$c',
              x: 40.0 + 120 * c,
              y: 150.0 + 14 * r,
            ),
        ...prose(y: 230),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.caption,
        BlockType.table,
        BlockType.paragraph,
      ]);
      expect(blocks[2].box.top, lessThanOrEqualTo(150));
      expect(blocks[2].box.bottom, greaterThanOrEqualTo(199));
      expect(blocks.map((b) => b.text).join(' '), isNot(contains('Head1')));
    });
  });

  group('tables (extension)', () {
    test('rows with fewer cells below the grid still belong to it', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Table 2. Corpus.', y: 130),
        for (var r = 0; r < 3; r++)
          for (var c = 0; c < 3; c++)
            line('cell$r$c', x: 40.0 + 120 * c, y: 150.0 + 14 * r),
        line('spam 3 family 7', x: 40, y: 192),
        line('Projects 16 + 1', x: 40, y: 206),
        ...prose(y: 240),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.caption,
        BlockType.table,
        BlockType.paragraph,
      ]);
      expect(blocks[2].box.bottom, greaterThanOrEqualTo(213));
    });
  });

  group('formulas', () {
    test('a display equation between prose lines is a formula region', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('x = a + b · c (1)', x: 150, y: 120),
        line('where a is the first term and b the second one.', y: 140),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[1].text, isEmpty);
    });

    test('consecutive equation lines form one formula region', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('∂tv1 − µ1∆v1 = v1(−m + αv2),', x: 120, y: 120),
        line('∂tv2 − µ2∆v2 = v2(r − βv1),', x: 120, y: 134),
        line('∂nv1 = ∂nv2 = 0,', x: 120, y: 148),
        ...prose(y: 170),
      ]);

      expect(blocks.where((b) => b.type == BlockType.formula), hasLength(1));
    });

    test('an equation number far right joins its formula', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('x = a + b · c', x: 120, y: 120),
        line('(2)', x: 400, y: 120),
        line('where a is the first term and b the second one.', y: 140),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[1].box.right, greaterThanOrEqualTo(415));
    });

    test('fraction parts of a display equation join the formula', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Eg − Eph', x: 160, y: 118),
        line('C = 2πf', x: 120, y: 128),
        line('NAWp − Nid', x: 160, y: 138),
        ...prose(y: 160),
      ]);

      expect(blocks.where((b) => b.type == BlockType.formula), hasLength(1));
      expect(blocks.map((b) => b.text).join(), isNot(contains('Eph')));
    });

    test('a justified prose line with a chemical formula stays text', () {
      final result = typed([
        line('this is ordinary body text with several words', y: 100),
        line('([Mg] ∼ 1 × 1020 cm−3 ), and a 150-nm layerxx', y: 112),
        line('this is ordinary body text with several words.', y: 124),
      ]);

      expect(result.map((t) => t.$1), [BlockType.paragraph]);
    });

    test('formulas in two columns on the same row stay apart', () {
      final blocks = reflow([
        ...column(
          [
            'left column text with several words in it',
            'and more words that continue the sentence',
          ],
          x: 40,
          y: 60,
        ),
        line('R = q(E − r)', x: 80, y: 100),
        line('(1)', x: 250, y: 100),
        ...column(
          [
            'right column text with several words in it',
            'and more words that continue the sentence',
          ],
          x: 310,
          y: 60,
        ),
        line('∂z F = N(z)', x: 360, y: 100),
        line('(3)', x: 530, y: 100),
      ]);

      final formulas = blocks.where((b) => b.type == BlockType.formula);
      expect(formulas, hasLength(2));
      for (final f in formulas) {
        expect(f.box.right - f.box.left, lessThan(260));
      }
    });

    test('inline math inside a sentence stays text', () {
      final result = typed([
        line('We write R for the real numbers and N := {1, 2, 3}.', y: 100),
        ...prose(y: 112),
      ]);

      expect(result.first.$1, BlockType.paragraph);
    });
  });
}
