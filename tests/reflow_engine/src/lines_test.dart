import 'package:reflow_engine/reflow_engine.dart';
import 'package:reflow_engine/src/lines.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('buildLines', () {
    test('groups characters on the same baseline into one line', () {
      final lines = buildLines(line('Hello world'));

      expect(lines, hasLength(1));
      expect(lines.single.text, 'Hello world');
    });

    test('orders lines top to bottom regardless of input order', () {
      final chars = [...line('second', y: 20), ...line('first')];

      final lines = buildLines(chars);

      expect(lines.map((l) => l.text), ['first', 'second']);
    });

    test('orders characters left to right within a line', () {
      final chars = line('abc').reversed.toList();

      expect(buildLines(chars).single.text, 'abc');
    });

    test('inserts a space for a wide gap even without a word marker', () {
      final left = line('foo');
      final right = line(
        'bar',
        x: 30,
      ).map((c) => c.copyWith(wordStart: false)).toList();

      expect(buildLines([...left, ...right]).single.text, 'foo bar');
    });

    test('keeps a slightly raised glyph (superscript) in the same line', () {
      final chars = [...line('x'), ...line('2', x: 5, y: -2, size: 6)];

      expect(buildLines(chars), hasLength(1));
    });

    test('keeps a high superscript marker (footnote star) in the line', () {
      // Star box overlaps the line body by less than half of its height.
      final chars = [
        ...line('Author'),
        ...line('*', x: 31, y: -1.7, size: 4.7),
      ];

      expect(buildLines(chars), hasLength(1));
    });

    test('does not merge two columns that share a baseline', () {
      // Content order: whole left column first, then the right column.
      final chars = [
        ...line('left one', x: 50),
        ...line('left two', x: 50, y: 12),
        ...line('right one', x: 100),
        ...line('right two', x: 100, y: 12),
      ];

      expect(buildLines(chars).map((l) => l.text), [
        'left one',
        'right one',
        'left two',
        'right two',
      ]);
    });

    test('keeps a comma that hangs below the baseline in the line', () {
      // Real geometry from the corpus: the comma overlaps the letter band
      // by only ~38 % of its height.
      const comma = TextChar(text: ',', box: BBox(30, 5.5, 31.7, 8.7));
      final chars = [
        ...line('Zeng', size: 8.1),
        comma,
        ...line('Gao', x: 36, size: 8.1),
      ];

      final lines = buildLines(chars);

      expect(lines, hasLength(1));
      expect(lines.single.text, contains(','));
    });

    test('keeps a raised marker that starts the line (e.g. *Author)', () {
      // The star's box lies entirely above the letters' top.
      const star = TextChar(text: '*', box: BBox(0, -1.7, 2.9, 1.6));
      final chars = [star, ...line('Corresponding', x: 4)];

      expect(buildLines(chars), hasLength(1));
    });

    test('keeps a degree sign after digits in the line (120° corners)', () {
      // Real geometry from the corpus (single_column_text, page 3).
      const chars = [
        TextChar(
          text: 'a',
          box: BBox(189.2, 554.46, 194.1, 560.1),
          wordStart: true,
        ),
        TextChar(text: 't', box: BBox(194.29, 552.82, 197.52, 560.13)),
        TextChar(
          text: '1',
          box: BBox(204.45, 551.83, 207.58, 560.06),
          wordStart: true,
        ),
        TextChar(text: '2', box: BBox(209.29, 551.83, 214.54, 560.06)),
        TextChar(text: '0', box: BBox(215.47, 551.83, 220.61, 560.19)),
        TextChar(text: '°', box: BBox(221.62, 551.82, 225.22, 555.55)),
        TextChar(
          text: 'c',
          box: BBox(231.76, 554.46, 236.28, 560.22),
          wordStart: true,
        ),
        TextChar(text: 'o', box: BBox(237.04, 554.46, 242.21, 560.22)),
        TextChar(text: 'r', box: BBox(242.7, 554.46, 246.7, 560.06)),
      ];

      expect(buildLines(chars).single.text, 'at 120° cor');
    });

    test('keeps a superscript citation followed by a capital word', () {
      // Real geometry (two_column_figures, page 1): "ultraviolet (UV).¹⁻³ For".
      const chars = [
        TextChar(
          text: 'u',
          box: BBox(199.92, 325.07, 204.6, 329.64),
          wordStart: true,
        ),
        TextChar(text: 'l', box: BBox(205, 322.75, 207.37, 329.55)),
        TextChar(text: 't', box: BBox(207.71, 323.78, 210.36, 329.64)),
        TextChar(text: 'r', box: BBox(210.4, 324.97, 213.69, 329.55)),
        TextChar(text: 'a', box: BBox(214.04, 324.97, 218.07, 329.64)),
        TextChar(text: 'v', box: BBox(218.08, 325.07, 222.65, 329.68)),
        TextChar(text: 'i', box: BBox(223.04, 322.75, 225.4, 329.55)),
        TextChar(text: 'o', box: BBox(225.93, 324.97, 230.33, 329.64)),
        TextChar(text: 'l', box: BBox(230.82, 322.75, 233.19, 329.55)),
        TextChar(text: 'e', box: BBox(233.65, 324.97, 237.62, 329.64)),
        TextChar(text: 't', box: BBox(237.95, 323.78, 240.6, 329.64)),
        TextChar(
          text: '(',
          box: BBox(245.94, 322.82, 248.49, 331.31),
          wordStart: true,
        ),
        TextChar(text: 'U', box: BBox(248.92, 322.96, 255.8, 329.68)),
        TextChar(text: 'V', box: BBox(256.13, 322.96, 262.92, 329.65)),
        TextChar(text: ')', box: BBox(263.45, 322.82, 266, 331.31)),
        TextChar(text: '.', box: BBox(267.18, 328.56, 268.29, 329.65)),
        TextChar(text: '1', box: BBox(269.79, 320.95, 271.87, 325.94)),
        TextChar(text: '–', box: BBox(272.65, 324.09, 276.34, 324.45)),
        TextChar(text: '3', box: BBox(276.66, 320.95, 279.53, 326.03)),
        TextChar(
          text: 'F',
          box: BBox(285.51, 322.96, 290.83, 329.55),
          wordStart: true,
        ),
        TextChar(text: 'o', box: BBox(291.07, 324.97, 295.46, 329.64)),
        TextChar(text: 'r', box: BBox(295.81, 324.97, 299.1, 329.55)),
      ];

      expect(buildLines(chars).single.text, 'ultraviolet (UV).1–3 For');
    });

    test('estimates the font size from letters, not tall brackets', () {
      // Brackets and parentheses are taller than the letters.
      const chars = [
        TextChar(text: '[', box: BBox(0, -2, 2, 9), wordStart: true),
        TextChar(text: 'F', box: BBox(2, 0, 6, 7)),
        TextChar(text: 'i', box: BBox(6, 0, 8, 7)),
        TextChar(text: ']', box: BBox(8, -2, 10, 9)),
        TextChar(text: '(', box: BBox(12, -2, 14, 9), wordStart: true),
        TextChar(text: 'b', box: BBox(14, 0, 18, 7)),
        TextChar(text: ')', box: BBox(18, -2, 20, 9)),
      ];

      expect(buildLines(chars).single.fontSize, closeTo(7, 0.01));
    });

    test('returns no lines for an empty page', () {
      expect(buildLines(const []), isEmpty);
    });

    test('reports the line box and font size', () {
      final l = buildLines(line('ab', x: 10, y: 100)).single;

      expect(l.box.left, 10);
      expect(l.box.top, 100);
      expect(l.fontSize, closeTo(7, 0.01));
    });
  });
}
