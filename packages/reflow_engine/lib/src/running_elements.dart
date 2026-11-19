import 'package:reflow_engine/src/lines.dart';
import 'package:reflow_engine/src/model.dart';

final _pageNumber = RegExp(r'^(page\s*)?(#+|[ivxlcdm]+)(\s*(of|/)\s*#+)?$');

/// Removes running headers/footers, page numbers and side-margin debris.
///
/// Tiny lines (up to two glyphs) lying completely in the left or right
/// 8 % of the page (remains of rotated stamps) are removed. Of the lines
/// in the top or bottom margin zone (9 % of the page height), a line is
/// removed if it is a bare page number, or if its text (digits ignored)
/// appears in the same zone on at least two pages and at least half of all
/// pages, or if it repeats text from the first page (alternating
/// title/author heads on later pages).
List<List<TextLine>> removeRunningElements(
  List<PageInput> pages,
  List<List<TextLine>> linesPerPage,
) {
  String? zoneKey(PageInput page, TextLine line) {
    final zone = line.box.bottom < 0.09 * page.height
        ? 'top'
        : line.box.top > 0.91 * page.height
        ? 'bottom'
        : null;
    if (zone == null) return null;
    return '$zone|${_normalize(line.text)}';
  }

  final pageCounts = <String, int>{};
  for (var i = 0; i < pages.length; i++) {
    final keys = {for (final line in linesPerPage[i]) ?zoneKey(pages[i], line)};
    for (final k in keys) {
      pageCounts[k] = (pageCounts[k] ?? 0) + 1;
    }
  }

  // Title and author lines live on the first page; alternating running
  // heads on later pages repeat them.
  final frontText = pages.isEmpty
      ? ''
      : [for (final line in linesPerPage[0]) _normalize(line.text)].join(' ');

  bool repeatsFrontMatter(TextLine line) {
    final text = _normalize(line.text);
    if (text.length < 8 || !text.contains(' ')) return false;
    return frontText.contains(text);
  }

  // Books print a changing chapter or section title on the baseline of the
  // page number: it goes with the number.
  bool besidePageNumber(PageInput page, List<TextLine> lines, TextLine line) {
    final key = zoneKey(page, line);
    if (key == null) return false;
    final zone = key.substring(0, key.indexOf('|'));
    return lines.any((other) {
      if (identical(other, line)) return false;
      final otherKey = zoneKey(page, other);
      if (otherKey == null || !otherKey.startsWith('$zone|')) return false;
      final size = line.fontSize > other.fontSize
          ? line.fontSize
          : other.fontSize;
      return _pageNumber.hasMatch(otherKey.substring(zone.length + 1)) &&
          (other.baseline - line.baseline).abs() <= 0.5 * size;
    });
  }

  return [
    for (var i = 0; i < pages.length; i++)
      [
        for (final line in linesPerPage[i])
          if (!_inSideMargin(pages[i], line) &&
              !_isRunning(zoneKey(pages[i], line), pageCounts, pages.length) &&
              !besidePageNumber(pages[i], linesPerPage[i], line) &&
              !(i > 0 &&
                  zoneKey(pages[i], line) != null &&
                  repeatsFrontMatter(line)))
            line,
      ],
  ];
}

bool _inSideMargin(PageInput page, TextLine line) =>
    line.chars.length <= 2 &&
    (line.box.right < 0.08 * page.width || line.box.left > 0.92 * page.width);

bool _isRunning(String? key, Map<String, int> counts, int pageCount) {
  if (key == null) return false;
  final text = key.substring(key.indexOf('|') + 1);
  if (_pageNumber.hasMatch(text)) return true;
  final count = counts[key] ?? 0;
  return count >= 2 && count >= pageCount / 2;
}

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'\d+'), '#')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
