import 'package:reflow_engine/src/classify.dart';
import 'package:reflow_engine/src/hyphenation.dart';
import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/paragraphs.dart';
import 'package:reflow_engine/src/reading_order.dart';
import 'package:reflow_engine/src/regions.dart';
import 'package:reflow_engine/src/running_elements.dart';

/// Turns the characters of a document into reflowable blocks.
class ReflowEngine {
  const new();

  /// Increase whenever the output for the same input changes.
  static const version = 4;

  ReflowDocument reflow(DocumentInput input) {
    final rawLines = [for (final page in input.pages) buildLines(page.chars)];
    final bodyLines = removeRunningElements(input.pages, rawLines);

    final flow = <(int, List<FlowItem>)>[];
    final textLines = <TextLine>[];
    for (var i = 0; i < input.pages.length; i++) {
      final found = detectRegions(bodyLines[i], input.pages[i]);
      final free = [
        for (final l in bodyLines[i])
          if (!found.consumed.contains(l)) l,
      ];
      textLines.addAll(free);
      // Regions take part in reading order as one-glyph stand-in lines.
      final anchors = {
        for (final r in found.regions)
          TextLine([TextChar(text: '\u0001', box: r.box)]): r,
      };
      final ordered = orderForReading(
        [...free, ...anchors.keys]..sort((a, b) {
          final byBaseline = a.baseline.compareTo(b.baseline);
          return byBaseline != 0
              ? byBaseline
              : a.box.left.compareTo(b.box.left);
        }),
      );
      flow.add((
        input.pages[i].number,
        [
          for (final l in ordered)
            if (anchors[l] case final region?)
              RegionItem(region)
            else
              LineItem(l),
        ],
      ));
    }

    final drafts = buildParagraphs(flow);
    final paragraphs = drafts.whereType<Paragraph>().toList();
    final types = classify(paragraphs, bodyFontSize(textLines));
    final texts = resolveHyphenation([for (final p in paragraphs) p.text]);
    final textOf = {
      for (var i = 0; i < paragraphs.length; i++) paragraphs[i]: texts[i],
    };

    final blocks = <ReflowBlock>[];
    final perPage = <int, int>{};
    for (final d in drafts) {
      final index = perPage[d.page] = (perPage[d.page] ?? -1) + 1;
      final id = 'p${d.page}b$index';
      switch (d) {
        case RegionDraft(:final region):
          blocks.add(
            ReflowBlock(
              id: id,
              type: region.type,
              text: '',
              page: d.page,
              box: region.box,
            ),
          );
        case Paragraph():
          final (type, level) = types[d]!;
          blocks.add(
            ReflowBlock(
              id: id,
              type: type,
              text: textOf[d]!,
              page: d.page,
              box: d.box,
              level: level,
            ),
          );
      }
    }
    return ReflowDocument(engineVersion: version, blocks: blocks);
  }
}
