import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

List<String> texts(List<PageInput> pages) => const ReflowEngine()
    .reflow(DocumentInput(pages: pages))
    .blocks
    .map((b) => b.text)
    .toList();

void main() {
  group('two columns', () {
    test('reads the left column completely before the right one', () {
      final p = page(1, [
        ...column([
          'Left one starts',
          'left one ends.',
          '    Left two starts',
          'left two ends.',
        ], x: 50),
        ...column([
          'Right one starts',
          'right one ends.',
          '    Right two starts',
          'right two ends.',
        ], x: 310),
      ]);

      expect(texts([p]), [
        'Left one starts left one ends.',
        'Left two starts left two ends.',
        'Right one starts right one ends.',
        'Right two starts right two ends.',
      ]);
    });

    test('keeps lines of different columns on the same baseline apart', () {
      final p = page(1, [
        ...column(['alpha alpha alpha', 'alpha alpha end.'], x: 50),
        ...column(['beta beta beta', 'beta beta end.'], x: 310),
      ]);

      expect(texts([p]), [
        'alpha alpha alpha alpha alpha end.',
        'beta beta beta beta beta end.',
      ]);
    });

    test('reads a full-width title before the columns below it', () {
      final p = page(1, [
        ...column(['Left text one', 'left text two.'], x: 50, y: 140),
        // Centered over both columns (body 50..380).
        line('A Title Spanning Both Columns', x: 107, y: 100, size: 16),
        ...column(['Right text one', 'right text two.'], x: 310, y: 140),
      ]);

      expect(texts([p]), [
        'A Title Spanning Both Columns',
        'Left text one left text two.',
        'Right text one right text two.',
      ]);
    });

    test('continues a paragraph from the left into the right column', () {
      final p = page(1, [
        ...column(['A sentence that starts', 'in the left column and'], x: 50),
        ...column(['ends in the right one.'], x: 310),
      ]);

      expect(texts([p]), [
        'A sentence that starts in the left column and ends in the right one.',
      ]);
    });
  });

  group('page breaks', () {
    test('continues an unfinished paragraph on the next page', () {
      final pages = [
        page(1, [
          line('This sentence does not', y: 100),
          line('end on page one but', y: 112),
        ]),
        page(2, [line('on page two.', y: 100)]),
      ];

      final blocks = const ReflowEngine()
          .reflow(DocumentInput(pages: pages))
          .blocks;

      expect(blocks.map((b) => b.text), [
        'This sentence does not end on page one but on page two.',
      ]);
      expect(blocks.single.page, 1);
    });

    test('starts a new paragraph on the next page after a full stop', () {
      final pages = [
        page(1, [line('Finished sentence here.', y: 100)]),
        page(2, [line('New paragraph.', y: 100)]),
      ];

      expect(texts(pages), ['Finished sentence here.', 'New paragraph.']);
    });
  });

  group('running headers, footers and page numbers', () {
    PageInput withMargins(int n, {String? header, String? footer}) => page(n, [
      if (header != null) line(header, x: 200, y: 20),
      line('Body text of page $n.', y: 300),
      if (footer != null) line(footer, x: 290, y: 770),
    ]);

    test('removes a header repeated on at least three pages', () {
      final pages = [
        for (var n = 1; n <= 3; n++) withMargins(n, header: 'Journal of Tests'),
      ];

      expect(texts(pages).where((t) => t.contains('Journal')), isEmpty);
    });

    test('keeps text that appears in the margin only once', () {
      final pages = [
        withMargins(1, header: 'Preprint notice'),
        withMargins(2),
        withMargins(3),
      ];

      expect(texts(pages), contains('Preprint notice'));
    });

    test('removes page numbers in the footer', () {
      final pages = [for (var n = 1; n <= 3; n++) withMargins(n, footer: '$n')];

      expect(texts(pages), [
        'Body text of page 1.',
        'Body text of page 2.',
        'Body text of page 3.',
      ]);
    });

    test('removes running heads that differ only in the page number', () {
      final pages = [
        for (var n = 1; n <= 3; n++)
          withMargins(n, header: 'Smith et al. Page $n'),
      ];

      expect(texts(pages).where((t) => t.contains('Smith')), isEmpty);
    });

    test('removes alternating running heads that repeat title or author', () {
      final pages = [
        page(1, [
          line('Deep Results on Reflow', x: 150, y: 100, size: 16),
          line('Jane Doe', x: 250, y: 130),
          line('Body text of page 1.', y: 300),
        ]),
        page(2, [
          line('Deep Results on Reflow', x: 200, y: 20),
          line('Body text of page 2.', y: 300),
        ]),
        page(3, [
          line('Jane Doe', x: 250, y: 20),
          line('Body text of page 3.', y: 300),
        ]),
      ];

      expect(texts(pages), [
        'Deep Results on Reflow',
        'Jane Doe',
        'Body text of page 1.',
        'Body text of page 2.',
        'Body text of page 3.',
      ]);
    });

    test('drops stray glyphs in the left or right page margin', () {
      final p = page(1, [
        line('.', x: 20, y: 300),
        line('Body text.', x: 60, y: 300),
        line('x', x: 585, y: 400),
      ]);

      expect(texts([p]), ['Body text.']);
    });

    test('drops vertical margin text (e.g. arXiv stamps)', () {
      final p = page(1, [
        verticalText('arXiv2611'),
        line('Body.', x: 50, y: 300),
      ]);

      expect(texts([p]), ['Body.']);
    });
  });

  group('hyphenation', () {
    List<String> joined(List<String> lines, {List<String> extra = const []}) =>
        texts([
          page(1, [
            for (var i = 0; i < lines.length; i++)
              line(lines[i], y: 100 + 12.0 * i),
            for (var i = 0; i < extra.length; i++)
              line(extra[i], y: 400 + 12.0 * i),
          ]),
        ]);

    test('joins a word split at the line end', () {
      expect(
        joined(['Some infor-', 'mation here.']).single,
        'Some information here.',
      );
    });

    test('keeps the hyphen of a compound continued with a capital', () {
      expect(
        joined(['The Offline-', 'Modus works.']).single,
        'The Offline-Modus works.',
      );
    });

    test('keeps the hyphen when the document spells the word with one', () {
      final result = joined(
        ['A well-', 'known case.'],
        extra: ['Another well-known case.'],
      );

      expect(result.first, 'A well-known case.');
    });

    test('keeps a dash followed by a number or symbol', () {
      expect(joined(['Range 10-', '20 here.']).single, 'Range 10-20 here.');
    });
  });
}
