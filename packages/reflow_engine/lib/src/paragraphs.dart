import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/regions.dart';
import 'package:reflow_engine/src/stats.dart';
import 'package:reflow_engine/src/text_patterns.dart';

/// Placeholder for a line-end hyphen whose fate is decided per document.
const hyphenJoint = '\u0000';

/// One element of a page in reading order: a text line or a region.
sealed class FlowItem;

class LineItem extends FlowItem {
  new(this.line);
  final TextLine line;
}

class RegionItem extends FlowItem {
  new(this.region);
  final Region region;
}

/// A block under construction: a paragraph of lines or a region.
sealed class Draft {
  new(this.page);

  /// 1-based page the block starts on.
  final int page;
}

class RegionDraft extends Draft {
  new(super.page, this.region);
  final Region region;
}

enum LineKind { body, listItem, caption, sectionHeading }

LineKind kindOf(String text) {
  if (isCaption(text)) return LineKind.caption;
  if (numberedHeadingDepth(text) != null || isSectionWord(text)) {
    return LineKind.sectionHeading;
  }
  if (startsListItem(text)) return LineKind.listItem;
  return LineKind.body;
}

/// A paragraph under construction.
class Paragraph extends Draft {
  new(super.page, TextLine first)
    : lines = [first],
      boxLines = [first],
      kind = kindOf(first.text);

  final List<TextLine> lines;
  final LineKind kind;

  /// Lines of the first contiguous piece (same page and column).
  final List<TextLine> boxLines;
  bool _boxClosed = false;

  BBox get box => boxLines.map((l) => l.box).reduce((a, b) => a.union(b));

  double get fontSize => median(lines.map((l) => l.fontSize));

  String get text {
    final buffer = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final current = lines[i].text;
      if (i == lines.length - 1) {
        buffer.write(current);
        break;
      }
      final joint = _joint(current, lines[i + 1].text);
      buffer
        ..write(
          joint == hyphenJoint
              ? current.substring(0, current.length - 1)
              : current,
        )
        ..write(joint);
    }
    return buffer.toString();
  }

  void add(TextLine line, {required bool jumped}) {
    if (jumped) _boxClosed = true;
    lines.add(line);
    if (!_boxClosed) boxLines.add(line);
  }
}

String _joint(String previous, String next) {
  if (previous.length < 2 || next.isEmpty || !previous.endsWith('-')) {
    return ' ';
  }
  final before = previous[previous.length - 2];
  if (before == ' ') return ' ';
  if (_isLetter(before) && _isLower(next[0])) return hyphenJoint;
  return '';
}

/// Builds paragraphs and region blocks over the whole document.
///
/// [pages] holds, per page, its number and its items in reading order.
List<Draft> buildParagraphs(List<(int, List<FlowItem>)> pages) {
  final drafts = <Draft>[];
  Paragraph? current;
  // A body paragraph interrupted by a figure, table or caption; reading
  // may continue it after the interruption.
  Paragraph? interrupted;
  var previousPage = -1;

  Paragraph start(int page, TextLine line) {
    final p = Paragraph(page, line);
    drafts.add(p);
    return p;
  }

  for (final (pageNumber, items) in pages) {
    final pitch = _typicalPitch([
      for (final i in items)
        if (i is LineItem) i.line,
    ]);
    for (final item in items) {
      switch (item) {
        case RegionItem(:final region):
          drafts.add(RegionDraft(pageNumber, region));
          if (region.type == BlockType.formula) {
            interrupted = null;
          } else if (current != null && current.kind == LineKind.body) {
            interrupted = current;
          }
          current = null;
          continue;
        case LineItem(:final line):
          var kind = kindOf(line.text);
          final pageChanged = previousPage != pageNumber;
          previousPage = pageNumber;
          // "Fig. 2.45. The calculation …" in the middle of a paragraph
          // is a reference, not the start of a caption.
          if (kind == LineKind.caption &&
              current != null &&
              !pageChanged &&
              continuesLine(current.lines.last, line, pitch)) {
            kind = LineKind.body;
          }

          if (current == null) {
            final resumed = interrupted;
            if (resumed != null &&
                kind == LineKind.body &&
                _continuesAfterJump(resumed.lines.last, line)) {
              resumed.add(line, jumped: true);
              current = resumed;
              interrupted = null;
            } else {
              if (kind != LineKind.caption) interrupted = null;
              current = start(pageNumber, line);
            }
            continue;
          }

          final prev = current.lines.last;
          final jumped = pageChanged || line.baseline <= prev.baseline;
          final bool startsNew;
          if (current.kind == LineKind.caption &&
              kind != LineKind.caption &&
              !jumped) {
            // "(b) …" inside a multi-line caption is not a list item.
            startsNew = _startsNewParagraph(current.lines, line, pitch);
          } else if (kind != LineKind.body ||
              current.kind == LineKind.sectionHeading) {
            startsNew = true;
          } else if (jumped) {
            startsNew = !_continuesAfterJump(prev, line);
          } else if (current.kind == LineKind.listItem) {
            startsNew = _startsNewListLine(current, line, pitch);
          } else {
            startsNew = _startsNewParagraph(current.lines, line, pitch);
          }

          if (!startsNew) {
            current.add(line, jumped: jumped);
            continue;
          }
          // A caption may sit inside a paragraph's flow.
          if (kind == LineKind.caption && current.kind == LineKind.body) {
            interrupted = current;
          }
          final resumed = interrupted;
          if (current.kind == LineKind.caption &&
              resumed != null &&
              kind == LineKind.body &&
              _continuesAfterJump(resumed.lines.last, line)) {
            resumed.add(line, jumped: true);
            current = resumed;
            interrupted = null;
            continue;
          }
          if (kind != LineKind.caption) interrupted = null;
          current = start(pageNumber, line);
      }
    }
  }
  return drafts;
}

double _typicalPitch(List<TextLine> lines) {
  // Up to 5× glyph height covers double spacing.
  final pitches = <double>[
    for (var i = 1; i < lines.length; i++)
      if (lines[i].baseline - lines[i - 1].baseline > 0 &&
          lines[i].baseline - lines[i - 1].baseline < 5 * lines[i].fontSize)
        lines[i].baseline - lines[i - 1].baseline,
  ];
  return pitches.isEmpty ? 0.0 : median(pitches);
}

/// Line distance to expect: the page's typical pitch, but at least what
/// the font size needs (titles in large fonts have a larger pitch).
double _expectedPitch(double pagePitch, double em) =>
    pagePitch > 1.6 * em ? pagePitch : 1.6 * em;

bool _sameFont(TextLine a, TextLine b) {
  final ratio = a.fontSize == 0 ? 1 : b.fontSize / a.fontSize;
  return ratio >= 0.85 && ratio <= 1.18;
}

bool _endsSentence(TextLine line) =>
    RegExp(r'[.!?:]["”’)\]]?$').hasMatch(line.text.trimRight());

/// After a column or page break: continue only an unfinished sentence.
bool _continuesAfterJump(TextLine prev, TextLine line) =>
    _sameFont(prev, line) &&
    prev.text.trim().isNotEmpty &&
    !_endsSentence(prev);

/// Inside a list item, lines with a hanging indent continue the item.
bool _startsNewListLine(Paragraph item, TextLine line, double pitch) {
  final first = item.lines.first;
  if (!_sameFont(item.lines.last, line)) return true;
  final em = line.fontSize;
  final gap = line.baseline - item.lines.last.baseline;
  if (gap > _expectedPitch(pitch, em) * 1.3) return true;
  return line.box.left < first.box.left - 0.5 * em;
}

bool _startsNewParagraph(
  List<TextLine> paragraph,
  TextLine line,
  double pitch,
) {
  final prev = paragraph.last;
  final em = line.fontSize > prev.fontSize ? line.fontSize : prev.fontSize;

  if (!_sameFont(prev, line)) return true;

  final gap = line.baseline - prev.baseline;
  if (gap > _expectedPitch(pitch, em) * 1.3) return true;

  // First-line indent (but not a shorter line centered under the previous
  // one, as in titles).
  final centered =
      line.box.width < 0.8 * prev.box.width &&
      ((line.box.left + line.box.right) - (prev.box.left + prev.box.right))
              .abs() <
          em;
  if (line.box.left - prev.box.left > 0.8 * em && !centered) return true;

  // Previous line ended a sentence well before the paragraph's right edge
  // (a short line without final punctuation is ragged or hyphenated text).
  final right = paragraph
      .map((l) => l.box.right)
      .reduce((a, b) => a > b ? a : b);
  if (paragraph.length > 1 &&
      prev.box.right < right - 5 * em &&
      _endsSentence(prev)) {
    return true;
  }

  return false;
}

bool _isLetter(String c) => c.toLowerCase() != c.toUpperCase();
bool _isLower(String c) => _isLetter(c) && c == c.toLowerCase();
