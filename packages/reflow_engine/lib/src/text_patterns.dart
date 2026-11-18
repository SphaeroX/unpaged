/// Text-level patterns shared by block classification and region detection.
library;

final _caption = RegExp(
  r'^(figure|fig\.|table|tab\.|abbildung|abb\.|tabelle)\s*'
  r'(\d+|[ivxlc]+)[.:]',
  caseSensitive: false,
);

final _tableCaption = RegExp(r'^(table|tab\.|tabelle)', caseSensitive: false);

final _listMarker = RegExp(
  r'^([•◦▪▸‣·*–-]|\(?\d{1,2}[.)]|\(?[a-z][.)]|\(?[ivx]{1,4}[.)])\s',
);

final _numberedHeading = RegExp(r'^(\d+(?:\.\d+)*)\.?\s+[A-Z]');

const _sectionWords = {
  'abstract',
  'introduction',
  'references',
  'bibliography',
  'acknowledgments',
  'acknowledgements',
  'conclusion',
  'conclusions',
  'appendix',
  'zusammenfassung',
  'einleitung',
  'literatur',
  'literaturverzeichnis',
  'fazit',
  'anhang',
};

final _realWord = RegExp(r'^[(\[]?[A-Za-z]?[a-z]{2,}[)\].,;:]*$');
final _mathChar = RegExp(
  '[=+−×÷·∑∏∫∂∆∇≤≥≈≠≡∈∉⊂⊆⊃∪∩→←↔⇒⇔∀∃√∝∞∥⟨⟩^′″∼'
  'αβγδεζηθικλμνξπρστυφχψωΓΔΘΛΞΠΣΦΨΩ]',
);

bool isCaption(String text) => _caption.hasMatch(text.trimLeft());

bool isTableCaption(String text) => _tableCaption.hasMatch(text.trimLeft());

bool startsListItem(String text) => _listMarker.hasMatch(text.trimLeft());

/// Depth of a numbered heading like "2.1 Spaces" (2), or `null`.
///
/// "1. Introduction" (number with a period) also reads like a list item,
/// so that form counts as a heading only when it is very short.
int? numberedHeadingDepth(String text) {
  final t = text.trim();
  final m = _numberedHeading.firstMatch(t);
  if (m == null || t.endsWith('.')) return null;
  final hasPeriod =
      t.length > m.group(1)!.length && t[m.group(1)!.length] == '.';
  if (words(t).length > (hasPeriod ? 5 : 10)) return null;
  return m.group(1)!.split('.').length;
}

/// "Abstract", "1 Introduction", "References" …
bool isSectionWord(String text) {
  final t = text
      .trim()
      .replaceFirst(RegExp(r'^\d+(\.\d+)*\.?\s*'), '')
      .replaceAll(RegExp(r'[.:]$'), '')
      .toLowerCase();
  return _sectionWords.contains(t);
}

List<String> words(String text) =>
    text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// Number of prose words (letters only, at least three, lowercase body).
int realWordCount(String text) =>
    words(text).where((w) => _realWord.hasMatch(w) && !_isMathName(w)).length;

int mathCharCount(String text) => _mathChar.allMatches(text).length;

/// Words of at least two letters in any case ("LLM", "Results").
int letterWordCount(String text) =>
    words(text)
        .where((w) => RegExp('[A-Za-zÀ-ÿ]{2,}').hasMatch(w) && !_isMathName(w))
        .length;

bool _isMathName(String w) => const {
  'sin',
  'cos',
  'tan',
  'exp',
  'log',
  'lim',
  'max',
  'min',
  'sup',
  'inf',
  'det',
  'arg',
  'mod',
}.contains(w.replaceAll(RegExp('[^a-z]'), ''));

/// A line that reads like a display equation rather than prose.
bool looksLikeFormula(String text) {
  final real = realWordCount(text);
  final math = mathCharCount(text);
  if (real == 0 && math >= 1) return true;
  return real <= 2 && math >= 2 && math >= real;
}

final _equationNumber = RegExp(r'^\(\d+[a-z]?\)$');

/// "(1)", "(12b)": the number of a display equation.
bool isEquationNumber(String text) =>
    _equationNumber.hasMatch(text.replaceAll(' ', ''));

/// A line that may belong to an adjacent display equation (fraction
/// parts, sub-/superscript rows, equation numbers).
bool mayJoinFormula(String text) =>
    isFormulaFragment(text) ||
    (realWordCount(text) <= 1 && mathCharCount(text) >= 1);

/// A tiny fragment such as "(1)", "2", "+", "i=1" next to an equation.
bool isFormulaFragment(String text) {
  final t = text.replaceAll(' ', '');
  return t.length <= 5 && realWordCount(text) == 0;
}

/// Prose stops a figure search: a line with several real words.
bool isProse(String text) => realWordCount(text) >= 6;
