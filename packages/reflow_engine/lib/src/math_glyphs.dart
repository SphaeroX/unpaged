import 'package:reflow_engine/src/model.dart';

/// Glyphs of math fonts without a Unicode mapping (Springer's
/// "MathematicalPi"), as PDFium reports them, and the signs they show.
const _signs = {'¼': '=', 'þ': '+', 'ð': '(', 'Þ': ')'};

/// An equation number set in such a font: "ð2:64Þ" for "(2.64)", "ð1Þ".
final _equationNumber = RegExp(r'ð ?\d+(?: ?[:.] ?\d+)*[a-z]? ?Þ');

/// Whether [input] sets its formulas in a math font without a Unicode
/// mapping: it has at least two equation numbers like "ð2:64Þ".
///
/// Those glyphs are ordinary letters elsewhere (Icelandic "með", "Það") and
/// "¼" is a fraction, so single glyphs prove nothing; such numbers do.
bool usesMathPiGlyphs(DocumentInput input) {
  var found = 0;
  for (final page in input.pages) {
    if (!page.chars.any((c) => c.text == 'Þ')) continue;
    final text = StringBuffer();
    for (final c in page.chars) {
      if (c.wordStart) text.write(' ');
      text.write(c.text);
    }
    found += _equationNumber.allMatches(text.toString()).length;
    if (found >= 2) return true;
  }
  return false;
}

/// Replaces the glyphs of such a math font with the signs they show, so
/// that display equations are recognised and inline math stays readable.
/// Returns [input] itself if the document does not use that font.
DocumentInput normalizeMathGlyphs(DocumentInput input) {
  if (!usesMathPiGlyphs(input)) return input;
  return DocumentInput(
    pages: [
      for (final page in input.pages)
        if (page.chars.any((c) => _signs.containsKey(c.text)))
          PageInput(
            number: page.number,
            width: page.width,
            height: page.height,
            graphics: page.graphics,
            chars: _normalize(page.chars),
          )
        else
          page,
    ],
  );
}

final _numberPart = RegExp(r'^[\d:.a-z]$');

List<TextChar> _normalize(List<TextChar> chars) {
  // The font prints the period of an equation number as a colon:
  // "ð2:64Þ" is "(2.64)".
  final periods = <int>{};
  for (var i = 0; i < chars.length; i++) {
    if (chars[i].text != 'ð') continue;
    var j = i + 1;
    while (j < chars.length &&
        j - i <= 10 &&
        _numberPart.hasMatch(chars[j].text)) {
      j++;
    }
    if (j > i + 1 && j < chars.length && chars[j].text == 'Þ') {
      for (var k = i + 1; k < j; k++) {
        if (chars[k].text == ':') periods.add(k);
      }
    }
  }
  return [
    for (var i = 0; i < chars.length; i++)
      if (periods.contains(i))
        TextChar(text: '.', box: chars[i].box, wordStart: chars[i].wordStart)
      else if (_signs[chars[i].text] case final sign?)
        TextChar(text: sign, box: chars[i].box, wordStart: chars[i].wordStart)
      else
        chars[i],
  ];
}
