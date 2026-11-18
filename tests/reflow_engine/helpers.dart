import 'package:reflow_engine/reflow_engine.dart';

/// Builds the characters of one text line.
///
/// Glyphs are `size * 0.5` wide and `size * 0.7` high; a space advances
/// the pen by `size * 0.25` and marks the next glyph as a word start.
List<TextChar> line(
  String text, {
  double x = 0,
  double y = 0,
  double size = 10,
}) {
  final chars = <TextChar>[];
  var pen = x;
  var wordStart = true;
  for (final rune in text.runes) {
    final c = String.fromCharCode(rune);
    if (c == ' ') {
      pen += size * 0.25;
      wordStart = true;
      continue;
    }
    chars.add(
      TextChar(
        text: c,
        box: BBox(pen, y, pen + size * 0.5, y + size * 0.7),
        wordStart: wordStart,
      ),
    );
    pen += size * 0.5;
    wordStart = false;
  }
  return chars;
}

PageInput page(int number, List<List<TextChar>> lines) => PageInput(
  number: number,
  width: 600,
  height: 800,
  chars: [for (final l in lines) ...l],
);

/// Lines of a column starting at [y] with a 12 pt pitch.
List<List<TextChar>> column(
  List<String> texts, {
  required double x,
  double y = 100,
}) => [
  for (var i = 0; i < texts.length; i++) line(texts[i], x: x, y: y + 12 * i),
];

/// Characters of [text] stacked vertically (rotated margin text).
List<TextChar> verticalText(String text, {double x = 10, double y = 300}) => [
  for (var i = 0; i < text.length; i++)
    TextChar(
      text: text[i],
      box: BBox(x, y - 6 * i - 5, x + 7, y - 6 * i),
      wordStart: i == 0,
    ),
];

const _xHeight = 'acemnorsuvwxz';
const _small = '.,;:-–—\'"`´';

/// Like [line], but with realistic glyph heights: x-height letters are
/// 0.48 × size high, punctuation 0.1 × size, everything else 0.7 × size.
List<TextChar> typesetLine(
  String text, {
  double x = 0,
  double y = 0,
  double size = 10,
}) {
  final baseline = y + size * 0.7;
  return [
    for (final c in line(text, x: x, y: y, size: size))
      () {
        final h = _small.contains(c.text)
            ? size * 0.1
            : _xHeight.contains(c.text)
            ? size * 0.48
            : size * 0.7;
        return TextChar(
          text: c.text,
          box: BBox(c.box.left, baseline - h, c.box.right, baseline),
          wordStart: c.wordStart,
        );
      }(),
  ];
}
