import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/paragraphs.dart';
import 'package:reflow_engine/src/stats.dart';
import 'package:reflow_engine/src/text_patterns.dart';

/// Typical body font size of the document (median over all glyphs).
double bodyFontSize(Iterable<TextLine> lines) => median([
  for (final l in lines)
    for (var i = 0; i < l.chars.length; i++) l.fontSize,
]);

/// Block type and heading level of every paragraph.
Map<Paragraph, (BlockType, int?)> classify(
  List<Paragraph> paragraphs,
  double bodySize,
) {
  final result = <Paragraph, (BlockType, int?)>{};
  final sizeHeadings = <Paragraph>[];
  for (final p in paragraphs) {
    final text = p.text;
    switch (p.kind) {
      case LineKind.caption:
        result[p] = (BlockType.caption, null);
      case LineKind.listItem:
        result[p] = (BlockType.listItem, null);
      case LineKind.sectionHeading:
        final depth = numberedHeadingDepth(text) ?? 1;
        result[p] = (BlockType.heading, (depth + 1).clamp(1, 6));
      case LineKind.body:
        if (_isLargeHeading(p, bodySize)) {
          sizeHeadings.add(p);
        } else {
          result[p] = (BlockType.paragraph, null);
        }
    }
  }
  // Larger fonts rank higher; sizes within 8 % share a level.
  final sizes = sizeHeadings.map((p) => p.fontSize).toList()
    ..sort((a, b) => b.compareTo(a));
  final levels = <double>[];
  for (final s in sizes) {
    if (levels.isEmpty || s < levels.last * 0.92) levels.add(s);
  }
  for (final p in sizeHeadings) {
    final level = levels.indexWhere((s) => p.fontSize >= s * 0.92) + 1;
    result[p] = (BlockType.heading, level.clamp(1, 6));
  }
  return result;
}

bool _isLargeHeading(Paragraph p, double bodySize) {
  // Titles may be split into several line pieces; the word limit below
  // keeps long large-font text out.
  if (p.lines.length > 8) return false;
  if (p.fontSize < 1.15 * bodySize) return false;
  final text = p.text.trimRight();
  // Headings are words, not equations or equation numbers.
  final wordCount = letterWordCount(text);
  final math = mathCharCount(text);
  if (wordCount == 0 || (wordCount == 1 && math > 0) || math > wordCount) {
    return false;
  }
  return !text.endsWith('.') && words(text).length <= 30;
}
