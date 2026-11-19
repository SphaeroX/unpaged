import 'package:flutter/foundation.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// A found occurrence: code units [start]..[end) of the searched text.
@immutable
class TextMatch {
  const new(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is TextMatch && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TextMatch($start, $end)';
}

/// All non-overlapping occurrences of [query] in [text], ignoring case.
///
/// Blanks around the query are ignored and a space inside it matches any
/// run of whitespace, so phrases are found across PDF line breaks.
List<TextMatch> findMatches(String text, String query) {
  final needle = query.trim().toLowerCase().replaceAll(_spaces, ' ');
  if (needle.isEmpty) return const [];
  // Folded text plus, per folded code unit, its offset in [text].
  final folded = StringBuffer();
  final origin = <int>[];
  var inSpace = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c.trim().isEmpty) {
      if (!inSpace) {
        folded.write(' ');
        origin.add(i);
      }
      inSpace = true;
      continue;
    }
    inSpace = false;
    final lower = c.toLowerCase();
    folded.write(lower);
    for (var k = 0; k < lower.length; k++) {
      origin.add(i);
    }
  }
  final haystack = folded.toString();
  final matches = <TextMatch>[];
  var from = 0;
  while (true) {
    final at = haystack.indexOf(needle, from);
    if (at < 0) break;
    final last = at + needle.length - 1;
    matches.add(TextMatch(origin[at], _endOf(text, origin[last])));
    from = at + needle.length;
  }
  return matches;
}

final _spaces = RegExp(r'\s+');

/// Exclusive end of the character at [i] (a whitespace run ends there).
int _endOf(String text, int i) {
  if (text[i].trim().isNotEmpty) return i + 1;
  var j = i;
  while (j < text.length && text[j].trim().isEmpty) {
    j++;
  }
  return j;
}

/// A match with some surrounding text, for a list of results.
@immutable
class Snippet {
  const new({required this.before, required this.match, required this.after});

  final String before;
  final String match;
  final String after;
}

/// [match] in [text] with up to [context] characters on each side; line
/// breaks become spaces, cut ends get an ellipsis.
Snippet snippetAround(String text, TextMatch match, {int context = 40}) {
  String flat(String s) => s.replaceAll(_spaces, ' ');
  final from = (match.start - context).clamp(0, text.length);
  final to = (match.end + context).clamp(0, text.length);
  final before = flat(text.substring(from, match.start));
  final after = flat(text.substring(match.end, to));
  return Snippet(
    before: from > 0 ? '…${before.trimLeft()}' : before,
    match: flat(text.substring(match.start, match.end)),
    after: to < text.length ? '${after.trimRight()}…' : after,
  );
}

/// A found place: in the original view a [page], in the eBook a block.
@immutable
class SearchHit {
  const new({
    required this.page,
    required this.match,
    required this.snippet,
    this.blockId,
  });

  /// 1-based page (of the block, in the eBook).
  final int page;

  /// eBook block the match lies in; `null` for page text.
  final String? blockId;

  /// Offsets in the page text or the block text.
  final TextMatch match;

  final Snippet snippet;
}

/// Most hits a search reports; more would only fill an endless list.
const searchHitLimit = 500;

/// Searches the texts of [pages] (page number, text) one after another.
Stream<SearchHit> searchPages(
  Stream<(int, String)> pages,
  String query, {
  int limit = searchHitLimit,
}) async* {
  var count = 0;
  await for (final (page, text) in pages) {
    for (final m in findMatches(text, query)) {
      yield SearchHit(page: page, match: m, snippet: snippetAround(text, m));
      if (++count >= limit) return;
    }
  }
}

/// Searches the text blocks of an eBook in reading order.
List<SearchHit> searchBlocks(
  ReflowDocument doc,
  String query, {
  int limit = searchHitLimit,
}) {
  final hits = <SearchHit>[];
  for (final block in doc.blocks) {
    if (block.type.isRegion) continue;
    for (final m in findMatches(block.text, query)) {
      hits.add(
        SearchHit(
          page: block.page,
          blockId: block.id,
          match: m,
          snippet: snippetAround(block.text, m),
        ),
      );
      if (hits.length >= limit) return hits;
    }
  }
  return hits;
}
