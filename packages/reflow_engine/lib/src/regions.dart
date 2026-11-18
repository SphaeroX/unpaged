import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/stats.dart';
import 'package:reflow_engine/src/text_patterns.dart';

/// A non-text area of a page (table, figure, formula).
class Region {
  new(this.type, this.box);

  final BlockType type;
  BBox box;
}

/// Result of region detection on one page.
class PageRegions {
  new(this.regions, this.consumed);

  final List<Region> regions;

  /// Lines that belong to a region and do not appear as text.
  final Set<TextLine> consumed;
}

/// Finds tables, figures and formulas among the [lines] of one page.
PageRegions detectRegions(List<TextLine> lines, PageInput page) {
  final regions = <Region>[];
  final consumed = <TextLine>{};
  final pitch = _pitch(lines);

  void consume(Region region, Iterable<TextLine> members) {
    regions.add(region);
    consumed.addAll(members);
  }

  // 1. Tables: rows of three or more short cells.
  for (final table in _gridTables(lines, page, pitch)) {
    _extendTable(table, lines, pitch);
    consume(Region(BlockType.table, _union(table)), table);
  }

  // 2. Captions: area above a figure caption, below a table caption.
  for (final caption in lines.where((l) => isCaption(l.text))) {
    if (consumed.contains(caption)) continue;
    final table = isTableCaption(caption.text);
    if (table && _hasRegionNear(regions, caption, pitch)) continue;
    final found =
        _sideCaptionArea(lines, consumed, caption, page, pitch) ??
        _captionArea(lines, consumed, caption, page, below: table) ??
        _captionArea(lines, consumed, caption, page, below: !table);
    if (found == null) continue;
    consume(
      Region(table ? BlockType.table : BlockType.figure, found.$1),
      found.$2,
    );
  }

  // 3. Formulas: equation lines plus adjacent fragments like "(1)".
  final free = [
    for (final l in lines)
      if (!consumed.contains(l)) l,
  ];
  final formulaLines = {
    for (final l in free)
      if (looksLikeFormula(l.text) && !_isFlushProse(l, free)) l,
  };
  var grew = true;
  while (grew) {
    grew = false;
    for (final l in free) {
      if (formulaLines.contains(l) ||
          isEquationNumber(l.text) ||
          !mayJoinFormula(l.text)) {
        continue;
      }
      if (formulaLines.any((f) => _near(f, l, 1.5 * pitch))) {
        formulaLines.add(l);
        grew = true;
      }
    }
  }
  final groups = _cluster(formulaLines.toList(), 1.5 * pitch);
  // An equation number belongs to the nearest formula on its left.
  for (final number in free.where((l) => isEquationNumber(l.text))) {
    List<TextLine>? best;
    var bestRight = double.negativeInfinity;
    for (final g in groups) {
      final box = _union(g);
      final sameRow =
          box.top < number.box.bottom && number.box.top < box.bottom;
      if (sameRow && box.right <= number.box.left && box.right > bestRight) {
        best = g;
        bestRight = box.right;
      }
    }
    best?.add(number);
  }
  for (final group in groups) {
    consume(Region(BlockType.formula, _union(group)), group);
  }
  return PageRegions(regions, consumed);
}

double _pitch(List<TextLine> lines) {
  final sorted = List.of(lines)
    ..sort((a, b) => a.baseline.compareTo(b.baseline));
  final gaps = <double>[
    for (var i = 1; i < sorted.length; i++)
      if (sorted[i].baseline - sorted[i - 1].baseline > 0.5 &&
          sorted[i].baseline - sorted[i - 1].baseline < 4 * sorted[i].fontSize)
        sorted[i].baseline - sorted[i - 1].baseline,
  ];
  if (gaps.isEmpty) {
    return 1.4 * median(lines.map((l) => l.fontSize));
  }
  return median(gaps);
}

BBox _union(Iterable<TextLine> lines) =>
    lines.map((l) => l.box).reduce((a, b) => a.union(b));

bool _overlapsX(BBox a, BBox b) => a.left < b.right && b.left < a.right;

bool _near(TextLine a, TextLine b, double gap) {
  final vertical = b.box.top > a.box.bottom
      ? b.box.top - a.box.bottom
      : a.box.top > b.box.bottom
      ? a.box.top - b.box.bottom
      : 0.0;
  final horizontal = b.box.left > a.box.right
      ? b.box.left - a.box.right
      : a.box.left > b.box.right
      ? a.box.left - b.box.right
      : 0.0;
  // An equation number may sit far right on the same row.
  if (vertical <= 0 && (isEquationNumber(a.text) || isEquationNumber(b.text))) {
    return true;
  }
  return vertical <= gap && horizontal <= 2 * a.fontSize;
}

/// A justified text line between prose lines, flush with them on both
/// sides, is prose even if it contains symbols ("∼ 1 × 10²⁰ cm⁻³").
bool _isFlushProse(TextLine line, List<TextLine> lines) {
  final em = line.fontSize;
  TextLine? neighbor({required bool above}) {
    TextLine? best;
    for (final l in lines) {
      if (identical(l, line) || !_overlapsX(l.box, line.box)) continue;
      final distance = above
          ? line.box.top - l.box.bottom
          : l.box.top - line.box.bottom;
      if (distance < -0.5 * em || distance > 1.5 * em) continue;
      if (best == null ||
          (above ? l.box.bottom > best.box.bottom : l.box.top < best.box.top)) {
        best = l;
      }
    }
    return best;
  }

  bool flushWith(TextLine? n) =>
      n != null &&
      realWordCount(n.text) >= 4 &&
      (n.box.left - line.box.left).abs() < 1.5 * em &&
      (n.box.right - line.box.right).abs() < 1.5 * em;

  return flushWith(neighbor(above: true)) || flushWith(neighbor(above: false));
}

/// Groups lines that are transitively near each other.
List<List<TextLine>> _cluster(List<TextLine> lines, double gap) {
  final groups = <List<TextLine>>[];
  for (final line in lines) {
    final touching = groups.where((g) => g.any((l) => _near(l, line, gap)));
    if (touching.isEmpty) {
      groups.add([line]);
    } else {
      final merged = [for (final g in touching) ...g, line];
      groups
        ..removeWhere(touching.contains)
        ..add(merged);
    }
  }
  return groups;
}

List<List<TextLine>> _gridTables(
  List<TextLine> lines,
  PageInput page,
  double pitch,
) {
  // Rows: short lines sharing a baseline, at least three per row.
  final cells = [
    for (final l in lines)
      if (l.box.width < 0.3 * page.width && !isCaption(l.text)) l,
  ]..sort((a, b) => a.baseline.compareTo(b.baseline));
  final rows = <List<TextLine>>[];
  for (final cell in cells) {
    if (rows.isNotEmpty &&
        (cell.baseline - rows.last.first.baseline).abs() <
            0.4 * cell.fontSize) {
      rows.last.add(cell);
    } else {
      rows.add([cell]);
    }
  }
  final gridRows = rows.where((r) => r.length >= 3).toList();

  // Tables: at least three grid rows close to each other.
  final tables = <List<List<TextLine>>>[];
  for (final row in gridRows) {
    if (tables.isNotEmpty &&
        row.first.baseline - tables.last.last.first.baseline <= 2.5 * pitch) {
      tables.last.add(row);
    } else {
      tables.add([row]);
    }
  }
  final result = <List<TextLine>>[];
  for (final table in tables.where((t) => t.length >= 3)) {
    final members = [for (final r in table) ...r];
    final box = _union(members);
    // Header cells with fewer columns and lines inside the grid area.
    final inside = lines.where(
      (l) =>
          !members.contains(l) &&
          !isCaption(l.text) &&
          l.box.left >= box.left - 2 &&
          l.box.right <= box.right + 2 &&
          l.box.top >= box.top - pitch &&
          l.box.bottom <= box.bottom + 2,
    );
    result.add([...members, ...inside]);
  }
  return result;
}

/// Adds neighbouring non-prose lines (rows with fewer cells, notes) that
/// lie within the table's width.
void _extendTable(List<TextLine> table, List<TextLine> lines, double pitch) {
  var grew = true;
  while (grew) {
    grew = false;
    final box = _union(table);
    for (final l in lines) {
      if (table.contains(l) || isCaption(l.text) || isProse(l.text)) continue;
      final inside =
          l.box.left >= box.left - pitch && l.box.right <= box.right + pitch;
      final distance = l.box.top > box.bottom
          ? l.box.top - box.bottom
          : box.top > l.box.bottom
          ? box.top - l.box.bottom
          : 0.0;
      if (inside && distance <= 1.2 * pitch) {
        table.add(l);
        grew = true;
      }
    }
  }
}

bool _hasRegionNear(List<Region> regions, TextLine caption, double pitch) =>
    regions.any(
      (r) =>
          _overlapsX(r.box, caption.box) &&
              (r.box.top - caption.box.bottom).abs() < 3 * pitch ||
          _overlapsX(r.box, caption.box) &&
              (caption.box.top - r.box.bottom).abs() < 3 * pitch,
    );

/// The area to the right of a side caption: a narrow caption flush with the
/// left edge of the text column, the figure or table beside it, starting at
/// the caption's top (common in books). Only accepted when label lines sit
/// in that area, so short ordinary captions keep the above/below search.
(BBox, List<TextLine>)? _sideCaptionArea(
  List<TextLine> lines,
  Set<TextLine> consumed,
  TextLine caption,
  PageInput page,
  double pitch,
) {
  final prose = [
    for (final l in lines)
      if (!consumed.contains(l) && isProse(l.text)) l,
  ];
  if (prose.isEmpty) return null;
  final columnLeft = prose
      .map((l) => l.box.left)
      .reduce((a, b) => a < b ? a : b);
  final columnRight = prose
      .map((l) => l.box.right)
      .reduce((a, b) => a > b ? a : b);
  final em = caption.fontSize;
  if ((caption.box.left - columnLeft).abs() > em) return null;

  // The caption may wrap onto further lines in its narrow column.
  final captionLines = [caption];
  var grew = true;
  while (grew) {
    grew = false;
    final last = captionLines.last;
    for (final l in lines) {
      if (captionLines.contains(l) || consumed.contains(l)) continue;
      final gap = l.box.top - last.box.bottom;
      if (gap >= -0.2 * em &&
          gap <= 0.8 * pitch &&
          (l.box.left - caption.box.left).abs() <= em &&
          !isProse(l.text) &&
          !isCaption(l.text)) {
        captionLines.add(l);
        grew = true;
        break;
      }
    }
  }
  final captionBox = _union(captionLines);
  if (captionBox.width > 0.45 * (columnRight - columnLeft)) return null;

  final gap = 0.5 * em;
  final left = captionBox.right + gap;
  bool beside(TextLine l) => l.box.right > left && l.box.left < columnRight;

  // Bounded above by the nearest line over the caption, below by the next
  // prose or caption line; without one the figure may reach the bottom
  // margin, estimated as the mirror of the top margin.
  final above = [
    for (final l in lines)
      if (l.box.bottom <= caption.box.top &&
          !captionLines.contains(l) &&
          _overlapsX(l.box, BBox(captionBox.left, 0, columnRight, 0)))
        l.box.bottom,
  ];
  final top = above.isEmpty
      ? caption.box.top - pitch
      : (above.reduce((a, b) => a > b ? a : b) + gap).clamp(
          caption.box.top - pitch,
          caption.box.top,
        );
  final stops = [
    for (final l in lines)
      if (l.box.top >= caption.box.top &&
          !captionLines.contains(l) &&
          !consumed.contains(l) &&
          beside(l) &&
          (isProse(l.text) || isCaption(l.text)))
        l.box.top,
  ];
  final pageTop = lines.map((l) => l.box.top).reduce((a, b) => a < b ? a : b);
  final bottomLimit = stops.isEmpty
      ? page.height - pageTop
      : stops.reduce((a, b) => a < b ? a : b) - gap;

  final labels = [
    for (final l in lines)
      if (!captionLines.contains(l) &&
          !consumed.contains(l) &&
          l.box.left >= left &&
          l.box.top >= top &&
          l.box.bottom <= bottomLimit)
        l,
  ];
  if (labels.isEmpty || labels.any((l) => isProse(l.text))) return null;
  final right = labels
      .map((l) => l.box.right)
      .fold(columnRight, (a, b) => a > b ? a : b);
  if (bottomLimit - top < 2.5 * em) return null;
  return (BBox(left, top, right, bottomLimit), labels);
}

/// The area between [caption] and the nearest prose line above (or below
/// if [below]) in the caption's column, with the label lines inside it.
(BBox, List<TextLine>)? _captionArea(
  List<TextLine> lines,
  Set<TextLine> consumed,
  TextLine caption,
  PageInput page, {
  required bool below,
}) {
  bool onSide(TextLine l) =>
      !identical(l, caption) &&
      !consumed.contains(l) &&
      (below
          ? l.box.top >= caption.box.bottom
          : l.box.bottom <= caption.box.top);
  int byDistance(TextLine a, TextLine b) => below
      ? a.box.top.compareTo(b.box.top)
      : b.box.bottom.compareTo(a.box.bottom);

  // The nearest prose line in the caption's column bounds the area …
  final stops =
      lines
          .where(
            (l) =>
                onSide(l) &&
                _overlapsX(l.box, caption.box) &&
                (isProse(l.text) || isCaption(l.text)),
          )
          .toList()
        ..sort(byDistance);
  final stop = stops.isEmpty ? null : stops.first;

  // … and, together with the caption, gives the column's width.
  // Labels may stick out of the text column a little.
  final textColumn = stop == null ? caption.box : caption.box.union(stop.box);
  final margin = 2 * caption.fontSize;
  final column = BBox(
    textColumn.left - margin,
    textColumn.top,
    textColumn.right + margin,
    textColumn.bottom,
  );
  final labels = [
    for (final l in lines)
      if (onSide(l) &&
          !identical(l, stop) &&
          _overlapsX(l.box, column) &&
          (stop == null ||
              (below
                  ? l.box.bottom <= stop.box.top
                  : l.box.top >= stop.box.bottom)))
        l,
  ];
  final left = [
    caption.box.left,
    if (stop != null) stop.box.left,
    ...labels.map((l) => l.box.left),
  ].reduce((a, b) => a < b ? a : b);
  final right = [
    caption.box.right,
    if (stop != null) stop.box.right,
    ...labels.map((l) => l.box.right),
  ].reduce((a, b) => a > b ? a : b);

  final gap = 0.25 * caption.fontSize;
  final double top;
  final double bottom;
  if (below) {
    top = caption.box.bottom + gap;
    bottom = stop != null
        ? stop.box.top - gap
        : (labels.isEmpty ? top : _union(labels).bottom);
  } else {
    bottom = caption.box.top - gap;
    top = stop != null
        ? stop.box.bottom + gap
        : (labels.isEmpty ? bottom : _union(labels).top);
  }
  // Too small to hold a figure or table.
  if (bottom - top < 2.5 * caption.fontSize) return null;
  return (BBox(left, top, right, bottom), labels);
}
