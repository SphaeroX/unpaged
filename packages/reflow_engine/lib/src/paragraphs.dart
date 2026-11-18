import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';
import 'package:reflow_engine/src/stats.dart';

/// Placeholder for a line-end hyphen whose fate is decided per document.
const hyphenJoint = '\u0000';

/// A paragraph under construction.
class Paragraph {
  new(this.page, TextLine first) : lines = [first], boxLines = [first];

  /// 1-based page the paragraph starts on.
  final int page;
  final List<TextLine> lines;

  /// Lines of the first contiguous piece (same page and column).
  final List<TextLine> boxLines;
  bool _boxClosed = false;

  BBox get box => boxLines.map((l) => l.box).reduce((a, b) => a.union(b));

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

/// Builds paragraphs over the whole document.
///
/// [pages] holds, per page, its number and its lines in reading order.
List<Paragraph> buildParagraphs(List<(int, List<TextLine>)> pages) {
  final paragraphs = <Paragraph>[];
  var previousPage = -1;
  for (final (pageNumber, lines) in pages) {
    final pitch = _typicalPitch(lines);
    for (final line in lines) {
      if (paragraphs.isEmpty) {
        paragraphs.add(Paragraph(pageNumber, line));
        previousPage = pageNumber;
        continue;
      }
      final current = paragraphs.last;
      final prev = current.lines.last;
      // Column or page break: reading continues further up or on a new page.
      final jumped =
          previousPage != pageNumber || line.baseline <= prev.baseline;
      final startsNew = jumped
          ? !_continuesAfterJump(prev, line)
          : _startsNewParagraph(current.lines, line, pitch);
      if (startsNew) {
        paragraphs.add(Paragraph(pageNumber, line));
      } else {
        current.add(line, jumped: jumped);
      }
      previousPage = pageNumber;
    }
  }
  return paragraphs;
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

bool _startsNewParagraph(
  List<TextLine> paragraph,
  TextLine line,
  double pitch,
) {
  final prev = paragraph.last;
  final em = line.fontSize > prev.fontSize ? line.fontSize : prev.fontSize;

  if (!_sameFont(prev, line)) return true;

  final gap = line.baseline - prev.baseline;
  final expected = pitch > 0 ? pitch : 1.25 * em;
  if (gap > expected * 1.3) return true;

  // First-line indent.
  if (line.box.left - prev.box.left > 0.8 * em) return true;

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
