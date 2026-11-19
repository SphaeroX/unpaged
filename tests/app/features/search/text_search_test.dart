import 'package:flutter_test/flutter_test.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/features/search/domain/text_search.dart';

void main() {
  group('findMatches', () {
    test('finds every occurrence, ignoring case', () {
      expect(findMatches('Cat, cat and CAT.', 'cat'), const [
        TextMatch(0, 3),
        TextMatch(5, 8),
        TextMatch(13, 16),
      ]);
    });

    test('a space in the query matches any run of whitespace', () {
      // PDF text breaks lines with "\r\n"; a phrase may span the break.
      expect(findMatches('the quick\r\nbrown fox', 'quick brown'), const [
        TextMatch(4, 16),
      ]);
    });

    test('ignores surrounding blanks of the query', () {
      expect(findMatches('a word here', '  word '), const [TextMatch(2, 6)]);
    });

    test('an empty or blank query finds nothing', () {
      expect(findMatches('text', ''), isEmpty);
      expect(findMatches('text', '   '), isEmpty);
    });

    test('matches do not overlap', () {
      expect(findMatches('aaaa', 'aa'), const [
        TextMatch(0, 2),
        TextMatch(2, 4),
      ]);
    });

    test('keeps offsets right for letters whose lower case is longer', () {
      // 'İ'.toLowerCase() has two code units; offsets must still point
      // into the original text.
      expect(findMatches('İstanbul and Ankara', 'ankara'), const [
        TextMatch(13, 19),
      ]);
    });
  });

  group('snippetAround', () {
    test('shows the match with some context on one line', () {
      final s = snippetAround(
        'one two three\nfour five six',
        const TextMatch(14, 18),
        context: 6,
      );
      expect(s.before, '…three ');
      expect(s.match, 'four');
      expect(s.after, ' five…');
    });

    test('no ellipsis at the start or end of the text', () {
      final s = snippetAround('short', const TextMatch(0, 5));
      expect(s.before, '');
      expect(s.match, 'short');
      expect(s.after, '');
    });
  });

  group('searchPages', () {
    test('yields the hits page by page with snippets', () async {
      final hits = await searchPages(
        Stream.fromIterable([(1, 'no luck'), (2, 'a cat; one more cat')]),
        'cat',
      ).toList();

      expect(hits.map((h) => (h.page, h.match)), [
        (2, const TextMatch(2, 5)),
        (2, const TextMatch(16, 19)),
      ]);
      expect(hits.first.blockId, isNull);
      expect(hits.first.snippet.match, 'cat');
    });

    test('stops after the limit', () async {
      final hits = await searchPages(
        Stream.fromIterable([(1, 'a a a'), (2, 'a a')]),
        'a',
        limit: 4,
      ).toList();

      expect(hits, hasLength(4));
    });
  });

  group('searchBlocks', () {
    ReflowBlock block(String id, BlockType type, String text, int page) =>
        ReflowBlock(
          id: id,
          type: type,
          text: text,
          page: page,
          box: const BBox(0, 0, 1, 1),
        );

    test('finds text blocks in reading order and skips crops', () {
      final doc = ReflowDocument(
        engineVersion: 1,
        blocks: [
          block('p1b0', BlockType.heading, 'Cats', 1),
          block('p1b1', BlockType.figure, 'cat picture', 1),
          block('p2b0', BlockType.paragraph, 'More about cats.', 2),
        ],
      );

      final hits = searchBlocks(doc, 'cat');

      expect(hits.map((h) => (h.blockId, h.page, h.match)), [
        ('p1b0', 1, const TextMatch(0, 3)),
        ('p2b0', 2, const TextMatch(11, 14)),
      ]);
    });
  });
}
