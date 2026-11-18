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
