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
