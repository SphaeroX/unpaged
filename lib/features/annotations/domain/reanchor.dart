import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// Where an eBook highlight sits: block, character offsets in the block's
/// text, and the quoted text with some context around it.
@immutable
class Anchor {
  const new({
    required this.blockId,
    required this.start,
    required this.end,
    required this.quote,
    this.prefix = '',
    this.suffix = '',
  });

  final String blockId;
  final int start;
  final int end;
  final String quote;
  final String prefix;
  final String suffix;

  Anchor moveTo(String blockId, int start) => Anchor(
    blockId: blockId,
    start: start,
    end: start + quote.length,
    quote: quote,
    prefix: prefix,
    suffix: suffix,
  );

  @override
  bool operator ==(Object other) =>
      other is Anchor &&
      other.blockId == blockId &&
      other.start == start &&
      other.end == end &&
      other.quote == quote &&
      other.prefix == prefix &&
      other.suffix == suffix;

  @override
  int get hashCode => Object.hash(blockId, start, end, quote, prefix, suffix);
}

const contextLength = 30;

/// The anchor of a selection [start]..[end) in a block's [text].
Anchor anchorFromSelection({
  required String blockId,
  required String text,
  required int start,
  required int end,
}) => Anchor(
  blockId: blockId,
  start: start,
  end: end,
  quote: text.substring(start, end),
  prefix: text.substring(max(0, start - contextLength), start),
  suffix: text.substring(end, min(text.length, end + contextLength)),
);

/// Finds [anchor] in [doc] again after the document was recomputed.
///
/// 1. Same block id and the quote still there → unchanged.
/// 2. Otherwise every occurrence of the quote in the document is a
///    candidate; the one whose surrounding text matches the stored
///    prefix/suffix best wins.
/// 3. No occurrence → `null` (the highlight is orphaned, not deleted).
Anchor? reanchor(ReflowDocument doc, Anchor anchor) {
  final block = doc.blocks.where((b) => b.id == anchor.blockId).firstOrNull;
  if (block != null &&
      anchor.end <= block.text.length &&
      block.text.substring(anchor.start, anchor.end) == anchor.quote) {
    return anchor;
  }
  if (anchor.quote.isEmpty) return null;

  Anchor? best;
  var bestScore = -1;
  for (final b in doc.blocks) {
    var index = b.text.indexOf(anchor.quote);
    while (index != -1) {
      final before = b.text.substring(0, index);
      final after = b.text.substring(index + anchor.quote.length);
      final score =
          _commonSuffix(before, anchor.prefix) +
          _commonPrefix(after, anchor.suffix);
      if (score > bestScore) {
        best = anchor.moveTo(b.id, index);
        bestScore = score;
      }
      index = b.text.indexOf(anchor.quote, index + 1);
    }
  }
  return best;
}

int _commonSuffix(String a, String b) {
  var n = 0;
  while (n < a.length &&
      n < b.length &&
      a[a.length - 1 - n] == b[b.length - 1 - n]) {
    n++;
  }
  return n;
}

int _commonPrefix(String a, String b) {
  var n = 0;
  while (n < a.length && n < b.length && a[n] == b[n]) {
    n++;
  }
  return n;
}
