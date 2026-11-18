import 'package:reflow_engine/src/paragraphs.dart';

final _hyphenated = RegExp(r'[^\s\-\u0000]+(?:-[^\s\-\u0000]+)+');
final _letters = RegExp(r'[^\W\d_]+$', unicode: true);
final _lettersStart = RegExp(r'^[^\W\d_]+', unicode: true);

/// Resolves line-end hyphen placeholders in [texts].
///
/// A split word keeps its hyphen if the document spells the joined word
/// with a hyphen elsewhere (e.g. "well-known"); otherwise the hyphen was
/// only hyphenation and is removed ("infor-mation" → "information").
List<String> resolveHyphenation(List<String> texts) {
  final vocabulary = <String>{
    for (final t in texts)
      for (final m in _hyphenated.allMatches(t)) _clean(m.group(0)!),
  };
  return [
    for (final t in texts)
      if (t.contains(hyphenJoint)) _resolve(t, vocabulary) else t,
  ];
}

String _resolve(String text, Set<String> vocabulary) {
  final parts = text.split(hyphenJoint);
  final buffer = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    final left = _letters.firstMatch(parts[i - 1])?.group(0) ?? '';
    final right = _lettersStart.firstMatch(parts[i])?.group(0) ?? '';
    final candidate = '${left.toLowerCase()}-${right.toLowerCase()}';
    final keep = vocabulary.any(
      (w) =>
          w == candidate ||
          w.startsWith('$candidate-') ||
          w.endsWith('-$candidate') ||
          w.contains('-$candidate-'),
    );
    buffer
      ..write(keep ? '-' : '')
      ..write(parts[i]);
  }
  return buffer.toString();
}

String _clean(String word) => word.toLowerCase().replaceAll(
  RegExp(r'^[^\p{L}]+|[^\p{L}]+$', unicode: true),
  '',
);
