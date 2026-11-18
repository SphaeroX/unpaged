import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/stats.dart';

/// Splits the lines of one page (in reading order) into paragraphs.
List<List<TextLine>> buildParagraphs(List<TextLine> lines) {
  if (lines.isEmpty) return const [];
  // Typical baseline distance; up to 5× glyph height covers double spacing.
  final pitches = <double>[
    for (var i = 1; i < lines.length; i++)
      if (lines[i].baseline - lines[i - 1].baseline > 0 &&
          lines[i].baseline - lines[i - 1].baseline < 5 * lines[i].fontSize)
        lines[i].baseline - lines[i - 1].baseline,
  ];
  final pitch = pitches.isEmpty ? 0.0 : median(pitches);

  final paragraphs = <List<TextLine>>[
    [lines.first],
  ];
  for (var i = 1; i < lines.length; i++) {
    final current = paragraphs.last;
    final line = lines[i];
    if (_startsNewParagraph(current, line, pitch)) {
      paragraphs.add([line]);
    } else {
      current.add(line);
    }
  }
  return paragraphs;
}

bool _startsNewParagraph(
  List<TextLine> paragraph,
  TextLine line,
  double pitch,
) {
  final prev = paragraph.last;
  final em = line.fontSize > prev.fontSize ? line.fontSize : prev.fontSize;

  final ratio = prev.fontSize == 0 ? 1 : line.fontSize / prev.fontSize;
  if (ratio < 0.85 || ratio > 1.18) return true;

  final gap = line.baseline - prev.baseline;
  final expected = pitch > 0 ? pitch : 1.25 * em;
  if (gap > expected * 1.3 || gap < 0) return true;

  // First-line indent.
  if (line.box.left - prev.box.left > 0.8 * em) return true;

  // Previous line ended well before the paragraph's right edge.
  final right = paragraph
      .map((l) => l.box.right)
      .reduce((a, b) => a > b ? a : b);
  if (paragraph.length > 1 && prev.box.right < right - 5 * em) return true;

  return false;
}
