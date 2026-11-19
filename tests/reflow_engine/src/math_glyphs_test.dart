import 'package:reflow_engine/reflow_engine.dart';
import 'package:reflow_engine/src/math_glyphs.dart';
import 'package:test/test.dart';

import '../helpers.dart';

const _body = 'this is ordinary body text with several words';

String _text(PageInput page) => page.chars.map((c) => c.text).join();

void main() {
  // Springer's math fonts have no Unicode mapping: PDFium reports "=" as
  // "¼", "+" as "þ" and the parentheses as "ð" and "Þ".
  final springer = DocumentInput(
    pages: [
      page(
        1,
        [
          line(_body, y: 60),
          line('Re ¼ Wg þ Wp', x: 150, y: 120),
          line('ð2:67Þ', x: 400, y: 120),
        ],
        graphics: const [BBox(1, 2, 3, 4)],
      ),
      page(2, [
        line('Sd ¼ 24=Re;', x: 150, y: 120),
        line('ð2:68Þ', x: 400, y: 120),
      ]),
    ],
  );

  group('usesMathPiGlyphs', () {
    test('is true for a document with equation numbers in that font', () {
      expect(usesMathPiGlyphs(springer), isTrue);
    });

    test('is false for Icelandic prose', () {
      final icelandic = DocumentInput(
        pages: [
          page(1, [
            line('Það er ekki hægt að gera þetta með þessum hætti', y: 60),
            line('og það var þá sem við fórum með Þór', y: 72),
          ]),
        ],
      );

      expect(usesMathPiGlyphs(icelandic), isFalse);
    });

    test('is false for a fraction sign in ordinary text', () {
      final recipe = DocumentInput(
        pages: [
          page(1, [line('¼ cup sugar', y: 60), line('1 ¼ cups flour', y: 72)]),
        ],
      );

      expect(usesMathPiGlyphs(recipe), isFalse);
    });

    test('a single such number is not enough', () {
      final one = DocumentInput(
        pages: [
          page(1, [line('ð1Þ', y: 60)]),
        ],
      );

      expect(usesMathPiGlyphs(one), isFalse);
    });
  });

  group('normalizeMathGlyphs', () {
    test('maps the glyphs of the math font to the signs they show', () {
      final result = normalizeMathGlyphs(springer);

      // The font prints the period of an equation number as a colon.
      expect(_text(result.pages[0]), endsWith('Re=Wg+Wp(2.67)'));
      expect(_text(result.pages[1]), 'Sd=24=Re;(2.68)');
    });

    test('keeps boxes, word starts, page sizes and graphics', () {
      final result = normalizeMathGlyphs(springer);

      for (var p = 0; p < springer.pages.length; p++) {
        final before = springer.pages[p];
        final after = result.pages[p];
        expect(after.number, before.number);
        expect(after.width, before.width);
        expect(after.height, before.height);
        expect(after.graphics, before.graphics);
        expect(after.chars.map((c) => c.box), before.chars.map((c) => c.box));
        expect(
          after.chars.map((c) => c.wordStart),
          before.chars.map((c) => c.wordStart),
        );
      }
    });

    test('leaves a document without that font untouched', () {
      final plain = DocumentInput(
        pages: [
          page(1, [line('Það er ¼ af þessu', y: 60)]),
        ],
      );

      expect(normalizeMathGlyphs(plain), same(plain));
    });
  });
}
