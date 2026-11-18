import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/stats.dart';

/// Orders the lines of one page for reading, detecting two-column regions.
///
/// A vertical gutter is searched in the middle of the text body. Runs of
/// lines that do not cross it form a column region; inside a region the
/// left column is read before the right one. Lines crossing the gutter
/// (titles, full-width text) separate regions.
List<TextLine> orderForReading(List<TextLine> lines) {
  if (lines.length < 3) return lines;
  final minGap = 1.1 * median(lines.map((l) => l.fontSize));
  final left = lines.map((l) => l.box.left).reduce((a, b) => a < b ? a : b);
  final right = lines.map((l) => l.box.right).reduce((a, b) => a > b ? a : b);
  final width = right - left;

  // Gutter: x in the central band crossed by the fewest lines.
  var bestCount = lines.length + 1;
  final bestXs = <double>[];
  for (var x = left + 0.3 * width; x <= left + 0.7 * width; x += 1) {
    final count = lines.where((l) => l.spans(x, minGap)).length;
    if (count < bestCount) {
      bestCount = count;
      bestXs
        ..clear()
        ..add(x);
    } else if (count == bestCount) {
      bestXs.add(x);
    }
  }
  final gutter = _centerOfLongestRun(bestXs);

  final ordered = <TextLine>[];
  var region = <TextLine>[];
  void flush() {
    ordered.addAll(_orderRegion(region, gutter, minGap));
    region = [];
  }

  for (final line in lines) {
    if (line.spans(gutter, minGap)) {
      flush();
      ordered.add(line);
    } else {
      region.add(line);
    }
  }
  flush();
  return ordered;
}

List<TextLine> _orderRegion(
  List<TextLine> region,
  double gutter,
  double minGap,
) {
  final leftSide = <TextLine>[];
  final rightSide = <TextLine>[];
  for (final line in region) {
    final split = line.splitAt(gutter, minGap);
    if (split != null) {
      leftSide.add(split.$1);
      rightSide.add(split.$2);
    } else if (line.box.right <= gutter) {
      leftSide.add(line);
    } else {
      rightSide.add(line);
    }
  }
  if (leftSide.isEmpty || rightSide.isEmpty || region.length < 3) {
    return region;
  }
  // Columns stand side by side: their vertical extents must overlap.
  double top(List<TextLine> ls) =>
      ls.map((l) => l.box.top).reduce((a, b) => a < b ? a : b);
  double bottom(List<TextLine> ls) =>
      ls.map((l) => l.box.bottom).reduce((a, b) => a > b ? a : b);
  final overlap =
      (bottom(leftSide) < bottom(rightSide)
          ? bottom(leftSide)
          : bottom(rightSide)) -
      (top(leftSide) > top(rightSide) ? top(leftSide) : top(rightSide));
  if (overlap <= 0) return region;
  return [...leftSide, ...rightSide];
}

double _centerOfLongestRun(List<double> xs) {
  var bestStart = 0;
  var bestLength = 0;
  var start = 0;
  for (var i = 1; i <= xs.length; i++) {
    if (i < xs.length && xs[i] - xs[i - 1] <= 1.0001) continue;
    if (i - start > bestLength) {
      bestLength = i - start;
      bestStart = start;
    }
    start = i;
  }
  return (xs[bestStart] + xs[bestStart + bestLength - 1]) / 2;
}
