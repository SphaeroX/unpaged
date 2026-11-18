import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/paragraphs.dart';

/// Turns the characters of a document into reflowable blocks.
class ReflowEngine {
  const new();

  /// Increase whenever the output for the same input changes.
  static const version = 1;

  ReflowDocument reflow(DocumentInput input) {
    final blocks = <ReflowBlock>[];
    for (final page in input.pages) {
      final lines = buildLines(page.chars);
      final paragraphs = buildParagraphs(lines);
      for (var i = 0; i < paragraphs.length; i++) {
        final p = paragraphs[i];
        blocks.add(
          ReflowBlock(
            id: 'p${page.number}b$i',
            type: BlockType.paragraph,
            text: p.map((l) => l.text).join(' '),
            page: page.number,
            box: p.map((l) => l.box).reduce((a, b) => a.union(b)),
          ),
        );
      }
    }
    return ReflowDocument(engineVersion: version, blocks: blocks);
  }
}
