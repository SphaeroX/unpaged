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
  final graphics = (page.graphics?.isEmpty ?? true) ? null : page.graphics;

  void consume(Region region, Iterable<TextLine> members) {
    regions.add(region);
    consumed.addAll(members);
  }

  // 0. A page set sideways (a wide table turned by 90°) cannot be reflowed:
  // it is shown as a whole.
  if (isSidewaysPage(page.chars)) {
    final upright = dropVerticalText(page.chars).toSet();
    final vertical = page.chars.where((c) => !upright.contains(c)).toList();
    final content = [
      ...vertical.map((c) => c.box),
      ...lines.map((l) => l.box),
      ...?graphics,
    ].reduce((a, b) => a.union(b));
    const pad = 4;
    final title = vertical.map((c) => c.text).join();
    consume(
      Region(
        RegExp('table|tabelle', caseSensitive: false).hasMatch(title)
            ? BlockType.table
            : BlockType.figure,
        BBox(
          (content.left - pad).clamp(0, page.width).toDouble(),
          (content.top - pad).clamp(0, page.height).toDouble(),
          (content.right + pad).clamp(0, page.width).toDouble(),
          (content.bottom + pad).clamp(0, page.height).toDouble(),
        ),
      ),
      lines,
    );
    return PageRegions(regions, consumed);
  }

  // Captions; further lines of side captions are caption text, never
  // labels or table cells.
  final column = _textColumn(lines);
  final captions = [
    for (final l in lines)
      if (isCaption(l.text) && !continuesTextAbove(lines, l, pitch)) l,
  ];
  final blocks = {
    for (final c in captions) c: _sideCaptionLines(lines, c, column, pitch),
  };
  final captionText = {for (final b in blocks.values) ...b.skip(1)};

  // 1. Tables: rows of three or more short cells.
  final cells = [
    for (final l in lines)
      if (!captionText.contains(l)) l,
  ];
  final grids = <Region, List<TextLine>>{};
  for (final table in _gridTables(cells, page, pitch)) {
    _extendTable(table, cells, pitch);
    final box = _withRules(_union(table), graphics, pitch);
    // Two grids inside one frame are one table.
    final same = regions.where((r) => _share(r.box, box) >= 0.5).firstOrNull;
    if (same != null) {
      same.box = same.box.union(box);
      grids[same]!.addAll(table);
      consumed.addAll(table);
    } else {
      final region = Region(BlockType.table, box);
      grids[region] = table;
      consume(region, table);
    }
  }

  // 2. Captions: the area beside a side caption, above a figure caption
  // or below a table caption. Where the graphics of the page are known,
  // an area that holds some is taken and shrunk to its content.
  // Glyphs running vertically (the title of a chart's y-axis).
  final upright = dropVerticalText(page.chars).toSet();
  final vertical = [
    for (final c in page.chars)
      if (!upright.contains(c)) c.box,
  ];

  BBox reachOf(TextLine caption) {
    final box = _union(blocks[caption]!);
    return _isSideCaption(blocks[caption]!, column)
        ? BBox(box.left, box.top, column!.$2, box.bottom)
        : caption.box;
  }

  // A grid table belongs to the table caption next to it: the one above
  // or beside it if there is one, else the one below it.
  final served = <TextLine>{};
  final captioned = <Region>{};
  for (final after in [true, false]) {
    for (final caption in captions.where((c) => isTableCaption(c.text))) {
      if (served.contains(caption)) continue;
      final reach = reachOf(caption);
      Region? nearest;
      var distance = 3 * pitch;
      for (final r in grids.keys) {
        if (captioned.contains(r) || !_overlapsX(r.box, reach)) continue;
        final level = r.box.top < reach.bottom && reach.top < r.box.bottom;
        final gap = after
            ? (level ? 0.0 : r.box.top - reach.bottom)
            : reach.top - r.box.bottom;
        if (gap >= -pitch && gap < distance) {
          nearest = r;
          distance = gap;
        }
      }
      if (nearest != null) {
        served.add(caption);
        captioned.add(nearest);
      }
    }
  }

  for (final caption in captions) {
    if (served.contains(caption) || consumed.contains(caption)) continue;
    final block = blocks[caption]!;
    final sideStyle = _isSideCaption(block, column);
    final table = isTableCaption(caption.text);
    // Cells that merely look like a table (the tick labels of a chart)
    // may turn out to be the labels of a figure.
    final taken = table
        ? consumed
        : {
            for (final l in consumed)
              if (!grids.entries.any(
                (g) => !captioned.contains(g.key) && g.value.contains(l),
              ))
                l,
          };
    final claimed = [for (final r in captioned) r.box];

    final side = sideStyle
        ? _sideCaptionArea(
            lines,
            taken,
            block,
            page,
            pitch,
            column!,
            graphics: graphics,
          )
        : null;
    _Area? area({required bool below, List<BBox>? graphics}) => _captionArea(
      lines,
      taken,
      block,
      captionText,
      page,
      pitch,
      below: below,
      graphics: graphics,
      claimed: claimed,
    );

    // In order of preference: beside a side caption, then above a figure
    // caption or below a table caption, then the other way round.
    var candidates = graphics == null
        ? const <_Area>[]
        : _withGraphics(
            [
              side,
              area(below: table, graphics: graphics),
              area(below: !table, graphics: graphics),
            ],
            graphics,
            page,
            pitch,
            keepAllLabels: table,
            vertical: table ? const [] : vertical,
          );
    if (candidates.isEmpty) {
      // No graphics there (or none known): go by the text alone.
      candidates = [
        if (side != null && side.labels.isNotEmpty) side,
        ?area(below: table),
        ?area(below: !table),
      ];
    }
    final type = table ? BlockType.table : BlockType.figure;
    for (final found in candidates) {
      if (!_claim(regions, type, found.box, keep: captioned)) continue;
      final region = Region(type, found.box);
      captioned.add(region);
      consume(region, [
        ...found.labels,
        // Whatever else is printed inside the region is part of it.
        if (graphics != null)
          for (final l in lines)
            if (!consumed.contains(l) &&
                !captionText.contains(l) &&
                !isCaption(l.text) &&
                !isProse(l.text) &&
                _contains(found.box, l.box))
              l,
      ]);
      break;
    }
  }

  // 3. Formulas: equation lines plus adjacent fragments like "(1)".
  final free = [
    for (final l in lines)
      if (!consumed.contains(l) && !captionText.contains(l)) l,
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

/// A candidate area for the figure or table of a caption.
class _Area {
  new(this.box, this.labels, {this.beside});

  final BBox box;

  /// Text lines inside the area (axis labels, table cells).
  final List<TextLine> labels;

  /// For the area beside a side caption: the caption. Its figure starts
  /// level with it.
  final BBox? beside;
}

double _area(BBox b) => b.width <= 0 || b.height <= 0 ? 0 : b.width * b.height;

BBox? _intersection(BBox a, BBox b) {
  final box = BBox(
    a.left > b.left ? a.left : b.left,
    a.top > b.top ? a.top : b.top,
    a.right < b.right ? a.right : b.right,
    a.bottom < b.bottom ? a.bottom : b.bottom,
  );
  return box.width > 0 && box.height > 0 ? box : null;
}

/// Common area of two boxes as a share of the smaller one.
double _share(BBox a, BBox b) {
  final common = _intersection(a, b);
  if (common == null) return 0;
  final smaller = _area(a) < _area(b) ? _area(a) : _area(b);
  return smaller <= 0 ? 0 : _area(common) / smaller;
}

bool _contains(BBox outer, BBox inner) =>
    inner.left >= outer.left - 1 &&
    inner.top >= outer.top - 1 &&
    inner.right <= outer.right + 1 &&
    inner.bottom <= outer.bottom + 1;

/// Distance between two boxes (0 if they touch or overlap).
double _distance(BBox a, BBox b) {
  final dx = a.left > b.right
      ? a.left - b.right
      : b.left > a.right
      ? b.left - a.right
      : 0.0;
  final dy = a.top > b.bottom
      ? a.top - b.bottom
      : b.top > a.bottom
      ? b.top - a.bottom
      : 0.0;
  return dx > dy ? dx : dy;
}

/// Whether [line] is printed inside one of the [graphics]: a cell of a
/// ruled table or the text of a diagram, not body text. A frame around
/// the whole page does not count.
bool _inGraphic(TextLine line, List<BBox>? graphics, PageInput page) =>
    graphics != null &&
    graphics.any(
      (g) =>
          _contains(g, line.box) &&
          !(g.width > 0.8 * page.width && g.height > 0.8 * page.height),
    );

/// A table's box widened by the rules drawn around it.
BBox _withRules(BBox table, List<BBox>? graphics, double pitch) {
  if (graphics == null) return table;
  final reach = BBox(
    table.left - pitch,
    table.top - pitch,
    table.right + pitch,
    table.bottom + pitch,
  );
  var box = table;
  for (final g in graphics) {
    final part = _intersection(g, reach);
    if (part != null && _area(part) >= 0.5 * _area(g)) box = box.union(g);
  }
  return box;
}

/// The candidate [areas] (in order of preference) that hold graphics of
/// the page, each shrunk to those graphics and the labels printed at them.
///
/// An area with only a fraction of what another one holds is dropped (a
/// stray rule against a picture). Empty if no area contains graphics.
List<_Area> _withGraphics(
  List<_Area?> areas,
  List<BBox> graphics,
  PageInput page,
  double pitch, {
  required bool keepAllLabels,
  List<BBox> vertical = const [],
}) {
  final found = <(_Area, double)>[];
  for (final area in areas.nonNulls) {
    // A graphic lying mostly inside the area belongs to it as a whole; one
    // that merely reaches into it belongs to something else.
    var parts = <BBox>[];
    for (final g in graphics) {
      final part = _intersection(g, area.box);
      if (part == null || _area(part) < 0.15 * _area(g)) continue;
      parts.add(_area(part) >= 0.5 * _area(g) ? g : part);
    }
    if (!keepAllLabels) {
      // A lone rule away from a picture is not part of it (the fraction
      // bar of an equation above the figure).
      bool thin(BBox b) => b.width < 3 || b.height < 3;
      final solid = parts.where((b) => !thin(b)).toList();
      if (solid.isNotEmpty) {
        parts = [
          for (final b in parts)
            if (!thin(b) || solid.any((s) => _distance(b, s) <= pitch)) b,
        ];
      }
    }
    if (parts.isEmpty) continue;
    final ink = parts
        .map((b) => _intersection(b, area.box))
        .nonNulls
        .fold<double>(0, (sum, b) => sum + _area(b));
    // The figure beside a side caption starts level with the caption.
    if (area.beside case final caption?) {
      bool level(BBox b) =>
          b.top <= caption.bottom + pitch && b.bottom >= caption.top - pitch;
      if (!parts.any(level) && !area.labels.any((l) => level(l.box))) {
        continue;
      }
    }
    var content = parts.reduce((a, b) => a.union(b));
    // Labels sit in, beside or right at the drawing; text further above
    // or below it (the last line of a paragraph, an equation) is not part
    // of the figure.
    final drawing = content;
    final labels = <TextLine>[];
    final open = List.of(area.labels);
    var grew = true;
    while (grew) {
      grew = false;
      for (final l in List.of(open)) {
        final reach = 1.6 * l.fontSize;
        if (keepAllLabels ||
            (l.box.top < drawing.bottom && l.box.bottom > drawing.top) ||
            _distance(l.box, content) <= reach ||
            labels.any((a) => _distance(l.box, a.box) <= reach)) {
          labels.add(l);
          open.remove(l);
          grew = true;
        }
      }
    }
    for (final l in labels) {
      content = content.union(l.box);
    }
    // So does a title running up the y-axis.
    final glyphs = List.of(vertical);
    grew = true;
    while (grew) {
      grew = false;
      for (final g in List.of(glyphs)) {
        if (_distance(g, content) <= pitch) {
          content = content.union(g);
          glyphs.remove(g);
          grew = true;
        }
      }
    }
    final weight = ink + labels.fold(0.0, (sum, l) => sum + _area(l.box));
    const pad = 2;
    found.add((
      _Area(
        BBox(
          (content.left - pad).clamp(0, page.width).toDouble(),
          (content.top - pad).clamp(0, page.height).toDouble(),
          (content.right + pad).clamp(0, page.width).toDouble(),
          (content.bottom + pad).clamp(0, page.height).toDouble(),
        ),
        labels,
      ),
      weight,
    ));
  }
  if (found.isEmpty) return const [];
  final most = found.map((f) => f.$2).reduce((a, b) => a > b ? a : b);
  return [
    for (final (area, weight) in found)
      if (weight >= 0.05 * most) area,
  ];
}

/// Whether a new region of [type] may take [box]. A figure swallows
/// tables found inside it (tick labels of a chart look like a grid) unless
/// they are in [keep]; otherwise an area that mostly belongs to another
/// region is refused.
bool _claim(
  List<Region> regions,
  BlockType type,
  BBox box, {
  required Set<Region> keep,
}) {
  if (type == BlockType.figure) {
    regions.removeWhere(
      (r) =>
          r.type == BlockType.table &&
          !keep.contains(r) &&
          _area(r.box) < _area(box) &&
          _share(r.box, box) >= 0.6,
    );
  }
  return !regions.any((r) => _share(r.box, box) >= 0.5);
}

/// Whether [line], although it begins like a caption ("Fig. 2.45. The
/// calculation …", "Table 3.6" ending a caption), just continues the text
/// of the line directly above it.
bool continuesTextAbove(List<TextLine> lines, TextLine line, double pitch) =>
    lines.any((above) => continuesLine(above, line, pitch));

/// Whether [line] directly follows [above] as the next line of its text.
bool continuesLine(TextLine above, TextLine line, double pitch) {
  final step = line.baseline - above.baseline;
  return !identical(above, line) &&
      step > 0.5 * above.fontSize &&
      step <= 1.35 * pitch &&
      isProse(above.text) &&
      _overlapsX(above.box, line.box) &&
      _sameSize(above, line) &&
      line.box.left >= above.box.left - 3 * above.fontSize &&
      line.box.left <= above.box.left + 0.5 * above.fontSize;
}

/// Left and right edge of the page's text column: the extent of its prose
/// lines, or of all lines on a page without prose.
(double, double)? _textColumn(List<TextLine> lines) {
  final prose = lines.where((l) => isProse(l.text)).toList();
  // A page of figures has too little prose to show the column.
  final basis = prose.length < 3 ? lines : prose;
  if (basis.isEmpty) return null;
  return (
    basis.map((l) => l.box.left).reduce((a, b) => a < b ? a : b),
    basis.map((l) => l.box.right).reduce((a, b) => a > b ? a : b),
  );
}

const _xHeightLetters = 'acemnorsuvwxz';

/// Height of the line's small letters. Unlike [TextLine.fontSize] it does
/// not depend on which tall letters the line happens to contain ("schemes"
/// measures smaller there, "on the jet border" larger).
double _xHeight(TextLine line) {
  final small = [
    for (final c in line.chars)
      if (_xHeightLetters.contains(c.text)) c.box.height,
  ];
  // Capitals and digits are about 1.45 x-heights tall.
  return small.isEmpty ? line.fontSize / 1.45 : median(small);
}

/// Whether [b] may be set in the font of [a].
bool _sameSize(TextLine a, TextLine b) {
  final ratio = _xHeight(a) == 0 ? 1.0 : _xHeight(b) / _xHeight(a);
  return ratio >= 0.85 && ratio <= 1.18;
}

/// [caption] and the lines it wraps onto in a narrow column at the left
/// edge of the text column (a side caption); just [caption] otherwise.
List<TextLine> _sideCaptionLines(
  List<TextLine> lines,
  TextLine caption,
  (double, double)? column,
  double pitch,
) {
  final block = [caption];
  if (column == null) return block;
  final em = caption.fontSize;
  if ((caption.box.left - column.$1).abs() > em) return block;
  final narrow = 0.45 * (column.$2 - column.$1);
  var grew = true;
  while (grew) {
    grew = false;
    final last = block.last;
    for (final l in lines) {
      if (block.contains(l)) continue;
      final gap = l.box.top - last.box.bottom;
      if (gap >= -0.2 * em &&
          gap <= 0.8 * pitch &&
          // Font sizes are glyph heights (~0.7 em): about 1.5 lines.
          l.baseline - last.baseline <= 2.2 * em &&
          (l.box.left - caption.box.left).abs() <= em &&
          l.box.right - caption.box.left <= narrow &&
          _sameSize(caption, l) &&
          !isCaption(l.text)) {
        block.add(l);
        grew = true;
        break;
      }
    }
  }
  return _isSideCaption(block, column) ? block : [caption];
}

/// A caption in a narrow column, flush with the left edge of the text.
bool _isSideCaption(List<TextLine> block, (double, double)? column) {
  if (column == null) return false;
  final box = _union(block);
  return (block.first.box.left - column.$1).abs() <= block.first.fontSize &&
      box.width <= 0.45 * (column.$2 - column.$1);
}

/// The area to the right of a side caption: a narrow caption flush with the
/// left edge of the text column, the figure or table beside it, starting at
/// the caption's top (common in books). Its labels may be empty (a bitmap
/// without text); the caller decides whether that is enough.
_Area? _sideCaptionArea(
  List<TextLine> lines,
  Set<TextLine> consumed,
  List<TextLine> captionLines,
  PageInput page,
  double pitch,
  (double, double) column, {
  List<BBox>? graphics,
}) {
  final caption = captionLines.first;
  final columnRight = column.$2;
  final em = caption.fontSize;
  final captionBox = _union(captionLines);

  final gap = 0.5 * em;
  final left = captionBox.right + gap;
  bool beside(TextLine l) => l.box.right > left && l.box.left < columnRight;

  // Bounded above by the nearest line over the caption, below by the next
  // line that starts under the caption (body text, the next caption) or
  // prose beside it; without one the figure may reach the bottom margin,
  // estimated as the mirror of the top margin (or the page's end if the
  // graphics will tell where the figure ends).
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
          ((l.box.left < left && l.box.top >= captionBox.bottom) ||
              (beside(l) &&
                  (isProse(l.text) || isCaption(l.text)) &&
                  !_inGraphic(l, graphics, page))))
        l.box.top,
  ];
  final pageTop = lines.map((l) => l.box.top).reduce((a, b) => a < b ? a : b);
  final bottomLimit = stops.isEmpty
      ? (graphics != null ? page.height : page.height - pageTop)
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
  if (labels.any((l) => isProse(l.text) && !_inGraphic(l, graphics, page))) {
    return null;
  }
  final right = labels
      .map((l) => l.box.right)
      .fold(columnRight, (a, b) => a > b ? a : b);
  if (bottomLimit - top < 2.5 * em || right - left < 2.5 * em) return null;
  return _Area(BBox(left, top, right, bottomLimit), labels, beside: captionBox);
}

/// The area between a caption ([captionLines]) and the nearest body text
/// above (or below if [below]) in the caption's column, with the label
/// lines inside it.
///
/// With the page's [graphics] given, an area without body text on that side
/// reaches the page edge and spans the graphics in the caption's column;
/// without them it ends with its outermost label. Regions [claimed] by
/// other captions are left out.
_Area? _captionArea(
  List<TextLine> lines,
  Set<TextLine> consumed,
  List<TextLine> captionLines,
  Set<TextLine> captionText,
  PageInput page,
  double pitch, {
  required bool below,
  List<BBox>? graphics,
  List<BBox> claimed = const [],
}) {
  final caption = captionLines.first;
  final captionBox = _union(captionLines);
  bool onSide(TextLine l) =>
      !captionLines.contains(l) &&
      !consumed.contains(l) &&
      (below ? l.box.top >= captionBox.bottom : l.box.bottom <= captionBox.top);
  int byDistance(TextLine a, TextLine b) => below
      ? a.box.top.compareTo(b.box.top)
      : b.box.bottom.compareTo(a.box.bottom);
  // The nearest body text in the caption's column bounds the area …
  final stops =
      lines
          .where(
            (l) =>
                onSide(l) &&
                _overlapsX(l.box, captionBox) &&
                (isProse(l.text) ||
                    isCaption(l.text) ||
                    captionText.contains(l)) &&
                !_inGraphic(l, graphics, page),
          )
          .toList()
        ..sort(byDistance);
  var stop = stops.isEmpty ? null : stops.first;
  // … including the short last lines of the paragraph it belongs to.
  if (!below && stop != null && isProse(stop.text)) {
    var grew = true;
    while (grew) {
      grew = false;
      final last = stop!;
      for (final l in lines) {
        final step = l.baseline - last.baseline;
        if (onSide(l) &&
            step > 0.5 * last.fontSize &&
            step <= 1.35 * pitch &&
            _sameSize(last, l) &&
            l.box.left >= last.box.left - 2.5 * last.fontSize &&
            l.box.left <= last.box.left + 0.5 * last.fontSize) {
          stop = l;
          grew = true;
          break;
        }
      }
    }
  }
  final bound = stop;

  // … and, together with the caption, gives the column's width.
  // Labels may stick out of the text column a little.
  final textColumn = bound == null ? captionBox : captionBox.union(bound.box);
  final margin = 2 * caption.fontSize;
  final column = BBox(
    textColumn.left - margin,
    textColumn.top,
    textColumn.right + margin,
    textColumn.bottom,
  );

  final gap = 0.25 * caption.fontSize;
  final near = below ? captionBox.bottom + gap : captionBox.top - gap;
  var far = bound == null
      ? null
      : (below ? bound.box.top - gap : bound.box.bottom + gap);

  // What another caption has taken is not available.
  var clipped = false;
  for (final c in claimed) {
    if (!_overlapsX(c, column)) continue;
    if (below
        ? c.top >= near - gap && (far == null || c.top < far)
        : c.bottom <= near + gap && (far == null || c.bottom > far)) {
      far = below ? c.top - gap : c.bottom + gap;
      clipped = true;
    }
  }

  // A table and a figure between their two captions share the area: it
  // is split at the widest gap between them.
  final isTable = isTableCaption(caption.text);
  if (graphics != null &&
      bound != null &&
      far != null &&
      !clipped &&
      below == isTable &&
      isCaption(bound.text) &&
      isTableCaption(bound.text) != isTable) {
    final range = BBox(
      column.left,
      below ? near : far,
      column.right,
      below ? far : near,
    );
    final items = [
      for (final l in lines)
        if (!captionLines.contains(l) &&
            !identical(l, bound) &&
            _contains(range, l.box))
          l.box,
      for (final g in graphics) ?_intersection(g, range),
    ]..sort((a, b) => a.top.compareTo(b.top));
    var reached = items.isEmpty ? range.top : items.first.bottom;
    var widest = 0.8 * pitch;
    double? split;
    for (final item in items.skip(1)) {
      if (item.top - reached > widest) {
        widest = item.top - reached;
        split = (item.top + reached) / 2;
      }
      if (item.bottom > reached) reached = item.bottom;
    }
    if (split != null) far = split;
  }

  final end = far;
  final labels = [
    for (final l in lines)
      if (onSide(l) &&
          !identical(l, bound) &&
          !captionText.contains(l) &&
          _overlapsX(l.box, column) &&
          (end == null ||
              (below ? l.box.bottom <= end + gap : l.box.top >= end - gap)))
        l,
  ];

  // Nothing bounds the area: the graphics in the caption's column do.
  final open = <BBox>[];
  if (bound == null && graphics != null) {
    final onSide = [
      for (final g in graphics)
        if (below
            ? g.top >= captionBox.bottom - gap && (end == null || g.top < end)
            : g.bottom <= captionBox.top + gap &&
                  (end == null || g.bottom > end))
          g,
    ];
    open.addAll(onSide.where((g) => _overlapsX(g, captionBox)));
    // A picture may consist of several parts set side by side: close
    // together, or in one row and without a caption of their own (the
    // picture of the next column has one).
    bool hasOwnCaption(BBox g) => lines.any((l) {
      final gap = below ? g.top - l.box.bottom : l.box.top - g.bottom;
      return isCaption(l.text) &&
          !captionLines.contains(l) &&
          _overlapsX(l.box, g) &&
          gap >= -pitch &&
          gap <= 3 * pitch;
    });
    bool sameRow(BBox a, BBox b) {
      final common =
          (a.bottom < b.bottom ? a.bottom : b.bottom) -
          (a.top > b.top ? a.top : b.top);
      final smaller = a.height < b.height ? a.height : b.height;
      return common >= 0.5 * smaller && _distance(a, b) <= 6 * pitch;
    }

    var grew = open.isNotEmpty;
    while (grew) {
      grew = false;
      for (final g in onSide) {
        if (open.contains(g)) continue;
        if (open.any((o) => _distance(g, o) <= pitch) ||
            (open.any((o) => sameRow(g, o)) && !hasOwnCaption(g))) {
          open.add(g);
          grew = true;
        }
      }
    }
  }
  final left = [
    captionBox.left,
    if (bound != null) bound.box.left,
    ...labels.map((l) => l.box.left),
    ...open.map((g) => g.left),
  ].reduce((a, b) => a < b ? a : b);
  final right = [
    captionBox.right,
    if (bound != null) bound.box.right,
    ...labels.map((l) => l.box.right),
    ...open.map((g) => g.right),
  ].reduce((a, b) => a > b ? a : b);

  final double top;
  final double bottom;
  if (below) {
    top = near;
    bottom =
        end ??
        (open.isNotEmpty
            ? page.height
            : (labels.isEmpty ? top : _union(labels).bottom));
  } else {
    bottom = near;
    top =
        end ??
        (open.isNotEmpty ? 0 : (labels.isEmpty ? bottom : _union(labels).top));
  }
  // Too small to hold a figure or table.
  if (bottom - top < 2.5 * caption.fontSize) return null;
  return _Area(BBox(left, top, right, bottom), labels);
}
