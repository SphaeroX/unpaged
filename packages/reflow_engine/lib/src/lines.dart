import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/stats.dart';

/// A run of glyphs sharing a baseline.
class TextLine {
  new(List<TextChar> chars)
    : chars = (List.of(chars)
        ..sort((a, b) => a.box.left.compareTo(b.box.left)));

  final List<TextChar> chars;

  late final BBox box = chars.map((c) => c.box).reduce((a, b) => a.union(b));

  /// Approximate font size: glyph height of the taller letters.
  late final double fontSize = percentile(chars.map((c) => c.box.height), 0.9);

  /// Approximate baseline: most glyphs sit on it.
  late final double baseline = median(chars.map((c) => c.box.bottom));

  late final String text = _buildText();

  String _buildText() {
    final buffer = StringBuffer();
    final spaceGap = fontSize * 0.3;
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (i > 0) {
        final gap = c.box.left - chars[i - 1].box.right;
        if (c.wordStart || gap > spaceGap) buffer.write(' ');
      }
      buffer.write(c.text);
    }
    return buffer.toString();
  }
}

/// Groups [chars] into lines, ordered top to bottom.
List<TextLine> buildLines(List<TextChar> chars) {
  final sorted = List.of(chars)..sort((a, b) => a.box.top.compareTo(b.box.top));
  final groups = <_Group>[];
  for (final c in sorted) {
    _Group? best;
    // 0.4 still catches raised markers (footnote stars, superscripts);
    // separate lines do not overlap at all.
    var bestOverlap = 0.4;
    // Only recent groups can still overlap a char further down the page.
    for (var i = groups.length - 1; i >= 0 && i >= groups.length - 8; i--) {
      final overlap = groups[i].overlapRatio(c.box);
      if (overlap >= bestOverlap) {
        best = groups[i];
        bestOverlap = overlap;
      }
    }
    if (best == null) {
      groups.add(_Group(c));
    } else {
      best.add(c);
    }
  }
  final lines = [for (final g in groups) TextLine(g.chars)]
    ..sort((a, b) => a.baseline.compareTo(b.baseline));
  return lines;
}

class _Group {
  new(TextChar c) : top = c.box.top, bottom = c.box.bottom, chars = [c];

  final List<TextChar> chars;
  double top;
  double bottom;

  /// Vertical overlap relative to the smaller of the two heights.
  double overlapRatio(BBox box) {
    final overlap =
        (box.bottom < bottom ? box.bottom : bottom) -
        (box.top > top ? box.top : top);
    final smaller = box.height < bottom - top ? box.height : bottom - top;
    if (smaller <= 0) return overlap >= 0 ? 1 : 0;
    return overlap / smaller;
  }

  void add(TextChar c) {
    chars.add(c);
    // Keep the band of the line body; tall glyphs only widen it a little.
    if (c.box.top < top) top = c.box.top;
    if (c.box.bottom > bottom) bottom = c.box.bottom;
  }
}
