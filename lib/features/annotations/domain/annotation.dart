import 'package:flutter/foundation.dart';
import 'package:paperflow/features/progress/domain/reading_position.dart';

/// The few highlight colours offered (ARGB, drawn semi-transparent).
enum HighlightColor {
  yellow(0xFFFFE066),
  green(0xFF8CE99A),
  blue(0xFF74C0FC),
  pink(0xFFF783AC);

  new(this.argb);

  final int argb;
}

/// A new highlight before it is stored.
///
/// Original view: anchored at [page] and the character range [start]..[end]
/// of PDFium's page text. eBook view (Task 11): anchored at [blockId] and
/// offsets, plus [quote] with [prefix]/[suffix] as context.
@immutable
class AnnotationDraft {
  const new({
    required this.view,
    required this.page,
    required this.start,
    required this.end,
    required this.quote,
    this.note,
    this.color = HighlightColor.yellow,
    this.blockId,
    this.prefix = '',
    this.suffix = '',
    this.engineVersion,
  });

  final ReadingView view;
  final int page;
  final int start;
  final int end;
  final String quote;
  final String? note;
  final HighlightColor color;
  final String? blockId;
  final String prefix;
  final String suffix;
  final int? engineVersion;
}

/// A stored highlight.
@immutable
class Annotation {
  const new({
    required this.id,
    required this.bookId,
    required this.view,
    required this.page,
    required this.start,
    required this.end,
    required this.quote,
    required this.color,
    required this.createdAt,
    this.note,
    this.blockId,
    this.prefix = '',
    this.suffix = '',
    this.engineVersion,
    this.orphaned = false,
  });

  final int id;
  final String bookId;
  final ReadingView view;
  final int page;
  final int start;
  final int end;
  final String quote;
  final HighlightColor color;
  final DateTime createdAt;
  final String? note;
  final String? blockId;
  final String prefix;
  final String suffix;
  final int? engineVersion;

  /// eBook only: the quote could not be found after a recomputation.
  final bool orphaned;
}
