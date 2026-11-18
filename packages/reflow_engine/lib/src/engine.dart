import 'package:reflow_engine/src/hyphenation.dart';
import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/paragraphs.dart';
import 'package:reflow_engine/src/reading_order.dart';
import 'package:reflow_engine/src/running_elements.dart';

/// Turns the characters of a document into reflowable blocks.
class ReflowEngine {
  const new();

  /// Increase whenever the output for the same input changes.
  static const version = 2;

  ReflowDocument reflow(DocumentInput input) {
    final rawLines = [for (final page in input.pages) buildLines(page.chars)];
    final bodyLines = removeRunningElements(input.pages, rawLines);
    final paragraphs = buildParagraphs([
      for (var i = 0; i < input.pages.length; i++)
        (input.pages[i].number, orderForReading(bodyLines[i])),
    ]);
    final texts = resolveHyphenation([for (final p in paragraphs) p.text]);

    final blocks = <ReflowBlock>[];
    final perPage = <int, int>{};
    for (var i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      final index = perPage[p.page] = (perPage[p.page] ?? -1) + 1;
      blocks.add(
        ReflowBlock(
          id: 'p${p.page}b$index',
          type: BlockType.paragraph,
          text: texts[i],
          page: p.page,
          box: p.box,
        ),
      );
    }
    return ReflowDocument(engineVersion: version, blocks: blocks);
  }
}
