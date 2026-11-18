import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';

/// Highlights and notes, stored only in the app's database.
class AnnotationRepository {
  new(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  Future<int> add(String bookId, AnnotationDraft d) => db
      .into(db.annotations)
      .insert(
        AnnotationsCompanion.insert(
          bookId: bookId,
          view: d.view,
          page: d.page,
          start: d.start,
          end: d.end,
          quote: d.quote,
          color: d.color,
          note: Value(d.note),
          blockId: Value(d.blockId),
          prefix: Value(d.prefix),
          suffix: Value(d.suffix),
          engineVersion: Value(d.engineVersion),
          createdAt: _clock(),
        ),
      );

  /// Highlights of one view of a book in reading order.
  Stream<List<Annotation>> watch(String bookId, ReadingView view) =>
      (db.select(db.annotations)
            ..where((a) => a.bookId.equals(bookId) & a.view.equalsValue(view))
            ..orderBy([
              (a) => OrderingTerm.asc(a.page),
              (a) => OrderingTerm.asc(a.start),
            ]))
          .watch()
          .map((rows) => rows.map(_toAnnotation).toList());

  Future<void> update(
    int id, {
    String? note,
    HighlightColor? color,
    bool clearNote = false,
  }) => (db.update(db.annotations)..where((a) => a.id.equals(id))).write(
    AnnotationsCompanion(
      note: clearNote ? const Value(null) : Value.absentIfNull(note),
      color: Value.absentIfNull(color),
    ),
  );

  Future<List<Annotation>> list(String bookId, ReadingView view) async =>
      (await (db.select(db.annotations)..where(
                (a) => a.bookId.equals(bookId) & a.view.equalsValue(view),
              ))
              .get())
          .map(_toAnnotation)
          .toList();

  /// Moves an eBook highlight after re-anchoring; [orphaned] if its quote
  /// was not found in the recomputed document.
  Future<void> updateAnchor(
    int id, {
    required int engineVersion,
    required bool orphaned,
    String? blockId,
    int? page,
    int? start,
    int? end,
  }) => (db.update(db.annotations)..where((a) => a.id.equals(id))).write(
    AnnotationsCompanion(
      blockId: Value.absentIfNull(blockId),
      page: Value.absentIfNull(page),
      start: Value.absentIfNull(start),
      end: Value.absentIfNull(end),
      engineVersion: Value(engineVersion),
      orphaned: Value(orphaned),
    ),
  );

  Future<void> delete(int id) =>
      (db.delete(db.annotations)..where((a) => a.id.equals(id))).go();

  Future<void> deleteBook(String bookId) =>
      (db.delete(db.annotations)..where((a) => a.bookId.equals(bookId))).go();

  static Annotation _toAnnotation(AnnotationRow r) => Annotation(
    id: r.id,
    bookId: r.bookId,
    view: r.view,
    page: r.page,
    start: r.start,
    end: r.end,
    quote: r.quote,
    color: r.color,
    createdAt: r.createdAt,
    note: r.note,
    blockId: r.blockId,
    prefix: r.prefix,
    suffix: r.suffix,
    engineVersion: r.engineVersion,
    orphaned: r.orphaned,
  );
}

final annotationRepositoryProvider = Provider<AnnotationRepository>(
  (ref) => AnnotationRepository(ref.watch(databaseProvider)),
);
