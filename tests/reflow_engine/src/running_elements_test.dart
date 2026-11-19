import 'package:reflow_engine/reflow_engine.dart';
import 'package:test/test.dart';

import '../helpers.dart';

List<List<TextChar>> _prose({double y = 100}) => [
  for (var i = 0; i < 4; i++)
    line(
      i == 3
          ? 'and this sentence ends the paragraph here.'
          : 'this is ordinary body text with several words',
      y: y + 12.0 * i,
    ),
];

void main() {
  group('running heads beside the page number', () {
    // Books print the chapter or section title next to the page number;
    // the title changes from page to page.
    final input = DocumentInput(
      pages: [
        page(1, [
          line('16', y: 40, size: 8),
          line('1 Conception of Arc Spraying Method', x: 250, y: 40, size: 8),
          ..._prose(),
        ]),
        page(2, [
          line('1.1 Essence of the Method', y: 40, size: 8),
          line('17', x: 500, y: 40, size: 8),
          ..._prose(),
        ]),
        page(3, [
          line('18', y: 40, size: 8),
          line('1 Conception of Arc Spraying Method', x: 250, y: 40, size: 8),
          ..._prose(),
        ]),
        page(4, [
          line('1.2 Research Plan of Arc Spraying', y: 40, size: 8),
          line('19', x: 500, y: 40, size: 8),
          ..._prose(),
        ]),
        page(5, [
          line('1.3 Structure', y: 760, size: 8),
          line('20', x: 500, y: 760, size: 8),
          ..._prose(),
        ]),
      ],
    );

    test('are removed together with it', () {
      final text = const ReflowEngine()
          .reflow(input)
          .blocks
          .map((b) => b.text)
          .join('\n');

      expect(text, isNot(contains('Conception')));
      expect(text, isNot(contains('Essence')));
      expect(text, isNot(contains('Research Plan')));
      expect(text, isNot(contains('Structure')), reason: 'running foot');
      expect(text, contains('ordinary body text'));
    });

    test('a line on another baseline stays', () {
      final blocks = const ReflowEngine()
          .reflow(
            DocumentInput(
              pages: [
                page(1, [
                  line('16', y: 40, size: 8),
                  line('A Heading In The Margin Zone', y: 58),
                  ..._prose(),
                ]),
              ],
            ),
          )
          .blocks;

      expect(blocks.first.text, 'A Heading In The Margin Zone');
    });
  });
}
