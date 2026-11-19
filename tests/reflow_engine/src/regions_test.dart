import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

List<ReflowBlock> reflow(List<List<TextChar>> lines, {List<BBox>? graphics}) =>
    const ReflowEngine()
        .reflow(DocumentInput(pages: [page(1, lines, graphics: graphics)]))
        .blocks;

const _body = 'this is ordinary body text with several words';

/// Body text ending in a full last line (column 0..205).
List<List<TextChar>> prose({double y = 400, int lines = 4}) => [
  for (var i = 0; i < lines; i++)
    line(
      i == lines - 1 ? 'and this sentence ends the paragraph here.' : _body,
      y: y + 12.0 * i,
    ),
];

Matcher _covers(BBox graphic, {double slack = 4}) => predicate<BBox>(
  (box) =>
      box.left <= graphic.left &&
      box.top <= graphic.top &&
      box.right >= graphic.right &&
      box.bottom >= graphic.bottom &&
      box.left >= graphic.left - slack &&
      box.top >= graphic.top - slack &&
      box.right <= graphic.right + slack &&
      box.bottom <= graphic.bottom + slack,
  'covers $graphic with at most $slack pt around it',
);

void main() {
  group('figures located by the graphics of the page', () {
    // Springer style: a narrow caption in the left margin, the picture (a
    // bitmap without any text) to its right, top-aligned with the caption.
    test('a picture beside a side caption is the figure, '
        'not the strip above the caption', () {
      const picture = BBox(90, 148, 200, 300);
      final blocks = reflow(
        [
          line(_body, y: 60),
          line(_body, y: 72),
          line(_body, y: 84),
          line('take place (Fig. 1.3).', y: 96),
          line('Fig. 1.3 Scheme of', y: 150, size: 8),
          line('formation', y: 160, size: 8),
        ],
        graphics: [picture],
      );

      expect(
        blocks.first.text,
        endsWith('take place (Fig. 1.3).'),
        reason: 'the last line of the paragraph is not part of the figure',
      );
      expect(
        blocks.singleWhere((b) => b.type == BlockType.caption).text,
        'Fig. 1.3 Scheme of formation',
      );
      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(picture));
    });

    test('stacked side captions each get the picture beside them', () {
      const first = BBox(90, 58, 200, 170);
      const second = BBox(90, 198, 200, 310);
      final blocks = reflow(
        [
          line('Fig. 2.8 Changes in', y: 60, size: 8),
          line('the surface', y: 70, size: 8),
          line('Fig. 2.9 Temperature', y: 200, size: 8),
          line('changing in shell', y: 210, size: 8),
          ...prose(y: 340),
        ],
        graphics: [first, second],
      );

      expect(
        [
          for (final b in blocks)
            if (b.type == BlockType.caption) b.text,
        ],
        [
          'Fig. 2.8 Changes in the surface',
          'Fig. 2.9 Temperature changing in shell',
        ],
      );
      final figures = blocks.where((b) => b.type == BlockType.figure).toList();
      expect(figures, hasLength(2));
      expect(figures[0].box, _covers(first));
      expect(figures[1].box, _covers(second));
    });

    test('labels of a chart beside a side caption belong to its figure', () {
      const chart = BBox(120, 150, 200, 250);
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Fig. 2.9 Temperature', y: 150, size: 8),
          line('changing in shell', y: 160, size: 8),
          line('2500', x: 100, y: 150, size: 7),
          line('t x 10000, s', x: 130, y: 256, size: 7),
          ...prose(y: 340),
        ],
        graphics: [chart],
      );

      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(const BBox(100, 150, 200, 261)));
      expect(blocks.map((b) => b.text).join(' '), isNot(contains('10000')));
    });

    test('a short caption under a picture keeps the picture above it', () {
      const picture = BBox(0, 120, 205, 250);
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Fig. 1.16 Process model', y: 258, size: 8),
          ...prose(y: 290),
        ],
        graphics: [picture],
      );

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.figure,
        BlockType.caption,
        BlockType.paragraph,
      ]);
      expect(blocks[1].box, _covers(picture));
    });

    test('a running head above a picture at the page top stays out', () {
      const picture = BBox(0, 80, 205, 250);
      final blocks = reflow(
        [
          line('16', y: 40, size: 8),
          line('1 Conception of Arc Spraying', x: 60, y: 40, size: 8),
          line('Fig. 1.4 The ratio of temperatures', y: 258, size: 8),
          ...prose(y: 290),
        ],
        graphics: [picture],
      );

      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(picture));
      expect(
        blocks.map((b) => b.text).join(' '),
        isNot(contains('Conception of Arc Spraying')),
      );
    });

    test('a table beside a side caption ends with its last row', () {
      final rows = [
        for (var i = 0; i < 4; i++) ...[
          line('Steel', x: 90, y: 150.0 + 12 * i, size: 8),
          line('1.25', x: 140, y: 150.0 + 12 * i, size: 8),
        ],
      ];
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Table 2.2 Calculating', y: 150, size: 8),
          line('results of cooling', y: 160, size: 8),
          ...rows,
        ],
        // The rules above and below the table.
        graphics: const [BBox(90, 144, 200, 147), BBox(90, 196, 200, 199)],
      );

      final table = blocks.singleWhere((b) => b.type == BlockType.table);
      expect(table.box, _covers(const BBox(90, 144, 200, 199)));
      expect(
        blocks.singleWhere((b) => b.type == BlockType.caption).text,
        'Table 2.2 Calculating results of cooling',
      );
    });

    test("a side caption's lines are not cells of the table beside it", () {
      // The caption lines share their baselines with the table rows.
      final rows = [
        for (var i = 0; i < 4; i++) ...[
          line('Steel', x: 90, y: 150.0 + 10 * i, size: 8),
          line('1.25', x: 130, y: 150.0 + 10 * i, size: 8),
          line('0.42', x: 170, y: 150.0 + 10 * i, size: 8),
        ],
      ];
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Table 2.13 The results', y: 150, size: 8),
          line('of compressed air', y: 160, size: 8),
          line('being fed in', y: 170, size: 8),
          ...rows,
          ...prose(y: 260),
        ],
        graphics: const [BBox(90, 144, 200, 147), BBox(90, 188, 200, 191)],
      );

      expect(
        blocks.singleWhere((b) => b.type == BlockType.caption).text,
        'Table 2.13 The results of compressed air being fed in',
      );
      final table = blocks.singleWhere((b) => b.type == BlockType.table);
      expect(table.box, _covers(const BBox(90, 144, 200, 191)));
    });

    test('a ruled table with sentences in its cells is found', () {
      const frame = BBox(0, 164, 205, 204);
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Table 2.14 The particles velocity', y: 150, size: 8),
          line('The distance from the nozzle face in mm', y: 168, size: 8),
          line('Spraying head with a combustion chamber', y: 180, size: 8),
          line('Spraying head without such a chamber', y: 192, size: 8),
          ...prose(y: 240),
        ],
        graphics: const [frame],
      );

      final table = blocks.singleWhere((b) => b.type == BlockType.table);
      expect(table.box, _covers(frame));
      expect(
        blocks.map((b) => b.text).join(' '),
        isNot(contains('Spraying head')),
      );
    });

    test('labels beside a picture belong to it, however wide the gap', () {
      const picture = BBox(0, 120, 150, 250);
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('Layer at', x: 166, y: 150),
          line('Surface', x: 166, y: 220),
          line(
            'Fig. 3.12 Comparison of the coating structures',
            y: 258,
            size: 8,
          ),
          ...prose(y: 290),
        ],
        graphics: const [picture],
      );

      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(const BBox(0, 120, 203.5, 250)));
      expect(blocks.map((b) => b.text).join(' '), isNot(contains('Surface')));
    });

    test('a display equation above a figure stays out of it', () {
      const picture = BBox(40, 180, 160, 250);
      final blocks = reflow(
        [
          ...prose(y: 60),
          line('E = a + b', x: 60, y: 124),
          line('c + d', x: 70, y: 138),
          line('Fig. 3.15 Scheme of the coated specimen', y: 258, size: 8),
          ...prose(y: 290),
        ],
        // The fraction bar of the equation and the picture.
        graphics: const [BBox(60, 134, 110, 135), picture],
      );

      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(picture));
      expect(blocks.map((b) => b.type), contains(BlockType.formula));
    });

    test('pictures set side by side above a short caption are one figure', () {
      const a = BBox(20, 100, 80, 170);
      const b = BBox(130, 100, 190, 170);
      final blocks = reflow(
        [line('Fig. 3.41 Variants', y: 180, size: 8), ...prose(y: 210)],
        graphics: const [a, b],
      );

      final figure = blocks.singleWhere((b) => b.type == BlockType.figure);
      expect(figure.box, _covers(const BBox(20, 100, 190, 170)));
    });

    test('a picture with its own caption in the next column is left alone', () {
      const left = BBox(0, 100, 90, 170);
      const right = BBox(120, 100, 210, 170);
      final blocks = reflow(
        [
          line('Fig. 1 Left picture', y: 180, size: 8),
          line('Fig. 2 Right picture', x: 120, y: 180, size: 8),
          ...prose(y: 210),
        ],
        graphics: const [left, right],
      );

      final figures = blocks.where((b) => b.type == BlockType.figure).toList()
        ..sort((a, b) => a.box.left.compareTo(b.box.left));
      expect(figures, hasLength(2));
      expect(figures[0].box, _covers(left));
      expect(figures[1].box, _covers(right));
    });

    test('without graphics on the page the text-only search still runs', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Figure 2: A picture without text.', y: 300),
        ...prose(y: 330),
      ], graphics: const []);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.figure,
        BlockType.caption,
        BlockType.paragraph,
      ]);
    });
  });

  group('formulas', () {
    test('what stands on the row of an equation number is a formula, '
        'even if its symbols read like words', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Re = Wg - Wp dp qp gg;', x: 60, y: 120),
        line('(2.67)', x: 180, y: 120),
        ...prose(y: 150),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[1].box.left, lessThanOrEqualTo(60));
      expect(blocks[1].box.right, greaterThanOrEqualTo(205));
    });

    test('a prose line before an equation number stays text', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('for this case the values in the table are taken from', y: 120),
        line('(3)', x: 300, y: 120),
        ...prose(y: 150),
      ]);

      expect(
        blocks.map((b) => b.text).join(' '),
        contains('the values in the table are taken from'),
      );
    });

    test('stacked numbered equations keep all their numbers', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('aT = Nu k0 / d,', x: 60, y: 120),
        line('(2.6)', x: 180, y: 120),
        line('Nu = 2 + 0.459 Re Pr,', x: 60, y: 134),
        line('(2.7)', x: 180, y: 134),
        line('Re = v q d / g', x: 60, y: 148),
        line('(2.8)', x: 180, y: 148),
        ...prose(y: 180),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks.map((b) => b.text).join(' '), isNot(contains('(2.')));
    });

    test('an equation with its number at the end of the same line '
        'is a formula', () {
      final blocks = reflow([
        ...prose(y: 60),
        // One run of glyphs: the number follows after a wide gap.
        [
          ...line('F = Fc - Fnp dnp cos anp ;', x: 40, y: 120),
          ...line('(2.81)', x: 165, y: 120),
        ],
        ...prose(y: 150),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
    });

    test('a sentence that ends with a reference to an equation stays text', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('It follows from the Eq. (2.66)', y: 120),
        ...prose(y: 150),
      ]);

      expect(blocks.map((b) => b.type), everyElement(BlockType.paragraph));
    });

    test('an equation number under a two-row equation joins it', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('dT dr2 = dr dT if DTr', x: 40, y: 120),
        line('= Tk - 2 Tk + Tk dr2', x: 60, y: 136),
        line('(2.18)', x: 180, y: 150),
        ...prose(y: 180),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
    });

    test('a short sentence with inline math between formulas stays text', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('∂tv1 − µ1∆v1 = v1(−m + αv2),', x: 60, y: 120),
        line('Thus, for every t ∈ [0, T],', y: 136),
        line('∂tv2 − µ2∆v2 = v2(r − βv1),', x: 60, y: 152),
        ...prose(y: 180),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[2].text, 'Thus, for every t ∈ [0, T],');
    });

    test('pieces of an equation on the row of its number are one formula', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('kP = r qg Wp gx gs gs', x: 30, y: 120),
        line('= 6 Cd', x: 150, y: 120),
        line('(2.29)', x: 215, y: 120),
        ...prose(y: 150),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[1].box.left, lessThanOrEqualTo(30));
      expect(blocks[1].box.right, greaterThanOrEqualTo(235));
    });

    test('a numbered equation of many word-like symbols is a formula', () {
      final blocks = reflow([
        ...prose(y: 60),
        [
          ...line(
            'rx = rx(z); ry = ry(z); sxy = sxz; rz = syz = sxz = 0:',
            y: 120,
          ),
          ...line('(3.25)', x: 262, y: 120),
        ],
        ...prose(y: 150),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
    });

    // Springer's math fonts: "¼" is "=", "þ" is "+", "ð…Þ" are parentheses.
    test('display equations in a math font without Unicode mapping are '
        'formulas, inline math becomes readable', () {
      final blocks = reflow([
        ...prose(y: 60),
        line('Re ¼ Wg - Wp dp qp gg;', x: 60, y: 120),
        line('ð2:67Þ', x: 180, y: 120),
        line('the capacity was approximated by y ¼ A1 þ A2 in all', y: 150),
        line('of the cases that were considered in this chapter.', y: 162),
        line('Sd ¼ 24=Re;', x: 60, y: 200),
        line('ð2:68Þ', x: 180, y: 200),
        ...prose(y: 230),
      ]);

      expect(blocks.map((b) => b.type), [
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
        BlockType.formula,
        BlockType.paragraph,
      ]);
      expect(blocks[2].text, contains('approximated by y = A1 + A2 in all'));
      final text = blocks.map((b) => b.text).join(' ');
      for (final glyph in ['¼', 'þ', 'ð', 'Þ']) {
        expect(text, isNot(contains(glyph)));
      }
    });
  });

  group('a page set sideways', () {
    // A wide table turned by 90°: its text runs bottom-up in columns.
    List<List<TextChar>> rotated({String title = 'Table 3.1 Temperatures'}) => [
      verticalText(title, x: 100, y: 600),
      for (var column = 1; column < 8; column++)
        verticalText(
          'Substrate 1530 1455 2050',
          x: 100.0 + 20 * column,
          y: 600,
        ),
      // Short numbers do not form vertical runs.
      line('17', x: 300, y: 300),
      line('10', x: 300, y: 320),
    ];

    test('is shown as one table instead of scattered fragments', () {
      final blocks = reflow(rotated());

      expect(blocks, hasLength(1));
      expect(blocks.single.type, BlockType.table);
      expect(blocks.single.box.left, lessThanOrEqualTo(100));
      expect(blocks.single.box.right, greaterThanOrEqualTo(307));
      expect(blocks.single.box.top, lessThanOrEqualTo(600 - 6 * 23 - 5));
      expect(blocks.single.box.bottom, greaterThanOrEqualTo(600));
    });

    test('is a figure if it carries no table caption', () {
      final blocks = reflow(rotated(title: 'Process flow of the plant'));

      expect(blocks.single.type, BlockType.figure);
    });

    test('a page with a rotated margin note stays text', () {
      final blocks = reflow([
        ...prose(y: 60, lines: 8),
        verticalText('arXiv:2401.00001v1 [cs.CL] 1 Jan 2024', x: 580),
      ]);

      expect(blocks.map((b) => b.type), [BlockType.paragraph]);
    });
  });

  group('pageNeedsGraphics', () {
    test('is true for a page with a figure or table caption', () {
      expect(
        pageNeedsGraphics(
          page(1, [...prose(y: 60), line('Fig. 1.3 Scheme', y: 150)]),
        ),
        isTrue,
      );
      expect(
        pageNeedsGraphics(page(1, [line('Table 2: Results.', y: 150)])),
        isTrue,
      );
    });

    test('is true for a page set sideways', () {
      expect(
        pageNeedsGraphics(
          page(1, [
            for (var column = 0; column < 8; column++)
              verticalText('Substrate 1530 1455', x: 100.0 + 20 * column),
          ]),
        ),
        isTrue,
      );
    });

    test('is false for a page of plain text', () {
      expect(pageNeedsGraphics(page(1, prose(y: 60))), isFalse);
    });
  });
}
