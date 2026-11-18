import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';

/// Reading positions per book and view.
class ReadingPositionRepository {
  new(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  Future<void> save(String bookId, ReadingPosition position) => db
      .into(db.readingPositions)
      .insertOnConflictUpdate(
        ReadingPositionsCompanion.insert(
          bookId: bookId,
          view: position.view,
          page: position.page,
          blockId: Value(position.blockId),
          progress: position.progress,
          updatedAt: _clock(),
        ),
      );

  Future<ReadingPosition?> load(String bookId, ReadingView view) async {
    final row =
        await (db.select(
              db.readingPositions,
            )..where((p) => p.bookId.equals(bookId) & p.view.equalsValue(view)))
            .getSingleOrNull();
    return row == null ? null : _toPosition(row);
  }

  /// The position in the view used last.
  Future<ReadingPosition?> lastUsed(String bookId) async {
    final row =
        await (db.select(db.readingPositions)
              ..where((p) => p.bookId.equals(bookId))
              ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toPosition(row);
  }

  /// Book id → progress of its most recently used view.
  Stream<Map<String, double>> watchProgress() =>
      (db.select(db.readingPositions)
            ..orderBy([(p) => OrderingTerm.asc(p.updatedAt)]))
          .watch()
          .map((rows) => {for (final r in rows) r.bookId: r.progress});

  Future<void> deleteBook(String bookId) => (db.delete(
    db.readingPositions,
  )..where((p) => p.bookId.equals(bookId))).go();

  static ReadingPosition _toPosition(ReadingPositionRow row) => ReadingPosition(
    view: row.view,
    page: row.page,
    blockId: row.blockId,
    progress: row.progress,
  );
}

final readingPositionRepositoryProvider = Provider<ReadingPositionRepository>(
  (ref) => ReadingPositionRepository(ref.watch(databaseProvider)),
);

final readingProgressProvider = StreamProvider<Map<String, double>>(
  (ref) => ref.watch(readingPositionRepositoryProvider).watchProgress(),
);
