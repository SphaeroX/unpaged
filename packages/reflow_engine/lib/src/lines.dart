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
  ///
  /// Lines made only of x-height letters ("ues.", "or") are scaled up so
  /// that they compare equal to lines with ascenders and capitals.
  late final double fontSize = _estimateFontSize();

  /// Approximate baseline: most glyphs sit on it.
  late final double baseline = median(chars.map((c) => c.box.bottom));

  late final String text = _buildText();

  /// Splits the line at the widest gap that contains [x], if that gap is at
  /// least [minGap] wide. Returns `null` if there is no such gap.
  (TextLine, TextLine)? splitAt(double x, double minGap) {
    for (var i = 1; i < chars.length; i++) {
      final gapStart = chars[i - 1].box.right;
      final gapEnd = chars[i].box.left;
      if (gapStart <= x && x <= gapEnd && gapEnd - gapStart >= minGap) {
        return (TextLine(chars.sublist(0, i)), TextLine(chars.sublist(i)));
      }
    }
    return null;
  }

  /// Whether glyphs of this line cover [x] (ignoring gaps of [minGap]+).
  bool spans(double x, double minGap) {
    if (x <= box.left || x >= box.right) return false;
    return splitAt(x, minGap) == null;
  }

  static const _xHeightLetters = 'acemnorsuvwxz';

  double _estimateFontSize() {
    // Brackets, parentheses and math symbols are taller than letters.
    final letters = chars.where((c) => _isAlphanumeric(c.text)).toList();
    if (letters.isEmpty) {
      return percentile(chars.map((c) => c.box.height), 0.9);
    }
    final size = percentile(letters.map((c) => c.box.height), 0.9);
    if (letters.every((c) => _xHeightLetters.contains(c.text))) {
      return size * 1.45;
    }
    return size;
  }

  static bool _isAlphanumeric(String s) =>
      s.toLowerCase() != s.toUpperCase() || RegExp(r'\d').hasMatch(s);

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

/// Groups [chars] into lines, ordered top to bottom, then left to right.
///
/// Works in two steps so that columns sharing a baseline stay apart:
/// 1. Runs: consecutive glyphs in content order on the same baseline.
/// 2. Runs merge into a line only if they overlap vertically and are
///    horizontally close (closer than a column gutter).
List<TextLine> buildLines(List<TextChar> chars) {
  final runs = _buildRuns(dropVerticalText(chars))
    ..sort((a, b) => a.top.compareTo(b.top));
  final groups = <_Group>[];
  for (final run in runs) {
    _Group? best;
    var bestOverlap = 0.4;
    for (final g in groups) {
      final overlap = g.overlapRatio(run);
      if (overlap >= bestOverlap && g.isNear(run)) {
        best = g;
        bestOverlap = overlap;
      }
    }
    if (best == null) {
      groups.add(run);
    } else {
      best.addAll(run);
    }
  }
  return [for (final g in groups) TextLine(g.chars)]..sort((a, b) {
    final byBaseline = a.baseline.compareTo(b.baseline);
    return byBaseline != 0 ? byBaseline : a.box.left.compareTo(b.box.left);
  });
}

/// Removes glyph sequences that run vertically (rotated margin text such as
/// arXiv stamps, rotated table headers).
List<TextChar> dropVerticalText(List<TextChar> chars) {
  bool vertical(TextChar a, TextChar b) {
    final size = [
      a.box.width,
      a.box.height,
      b.box.width,
      b.box.height,
    ].reduce((x, y) => x > y ? x : y);
    final dx = (a.box.left + a.box.right) / 2 - (b.box.left + b.box.right) / 2;
    final dy = a.box.centerY - b.box.centerY;
    return dx.abs() < 0.25 * size &&
        dy.abs() >= 0.3 * size &&
        dy.abs() <= 1.5 * size;
  }

  final drop = List.filled(chars.length, false);
  var start = 0;
  for (var i = 1; i <= chars.length; i++) {
    if (i < chars.length && vertical(chars[i - 1], chars[i])) continue;
    if (i - start >= 4) {
      for (var k = start; k < i; k++) {
        drop[k] = true;
      }
    }
    start = i;
  }
  return [
    for (var i = 0; i < chars.length; i++)
      if (!drop[i]) chars[i],
  ];
}

/// Whether the page is set sideways: a large share of its glyphs runs
/// vertically (a wide table turned by 90°), not just a margin note.
bool isSidewaysPage(List<TextChar> chars) {
  final vertical = chars.length - dropVerticalText(chars).length;
  return vertical >= 40 && vertical >= 0.3 * chars.length;
}

List<_Group> _buildRuns(List<TextChar> chars) {
  final runs = <_Group>[];
  _Group? current;
  for (final c in chars) {
    if (current != null && current.continuesWith(c)) {
      current.add(c);
    } else {
      current = _Group([c]);
      runs.add(current);
    }
  }
  return runs;
}

class _Group {
  new(List<TextChar> chars) : chars = List.of(chars) {
    _update();
  }

  final List<TextChar> chars;
  late double top;
  late double bottom;
  late double left;
  late double right;
  late double height;

  void _update() {
    top = median(chars.map((c) => c.box.top));
    bottom = median(chars.map((c) => c.box.bottom));
    left = chars.map((c) => c.box.left).reduce((a, b) => a < b ? a : b);
    right = chars.map((c) => c.box.right).reduce((a, b) => a > b ? a : b);
    height = percentile(chars.map((c) => c.box.height), 0.9);
  }

  void add(TextChar c) {
    chars.add(c);
    _update();
  }

  void addAll(_Group other) {
    chars.addAll(other.chars);
    _update();
  }

  /// Whether [c] directly follows the last glyph on the same baseline.
  bool continuesWith(TextChar c) {
    final last = chars.last;
    final h = height > c.box.height ? height : c.box.height;
    final gap = c.box.left - last.box.right;
    if (gap < -0.5 * h || gap > 3 * h) return false;
    if (_isSmall(c.box.height, c.box.top, c.box.bottom)) return true;
    return _ratio(top, bottom, c.box.top, c.box.bottom) >= 0.5;
  }

  /// Small glyphs (commas, periods, superscripts, degree signs) sit above
  /// or below the letter body; they belong to the line if they touch its
  /// band widened by 35 % of the line height. Superscript digits reach
  /// ~75 % of the line height, hence the 0.8 limit.
  bool _isSmall(double h, double t, double b) =>
      h < 0.8 * height && t < bottom + 0.35 * height && b > top - 0.35 * height;

  /// Vertical overlap with [other] relative to the smaller body height.
  double overlapRatio(_Group other) {
    if (_isSmall(other.height, other.top, other.bottom) ||
        other._isSmall(height, top, bottom)) {
      return 1;
    }
    return _ratio(top, bottom, other.top, other.bottom);
  }

  /// Horizontally closer than a column gutter.
  bool isNear(_Group other) {
    final h = height > other.height ? height : other.height;
    final gap = other.left > right ? other.left - right : left - other.right;
    return gap <= 1.2 * h;
  }

  static double _ratio(double t1, double b1, double t2, double b2) {
    final overlap = (b1 < b2 ? b1 : b2) - (t1 > t2 ? t1 : t2);
    final smaller = (b1 - t1) < (b2 - t2) ? b1 - t1 : b2 - t2;
    if (smaller <= 0) return overlap >= 0 ? 1 : 0;
    return overlap / smaller;
  }
}
