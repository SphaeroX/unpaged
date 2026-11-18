import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';

part 'app_database.g.dart';

/// State of the background reflow computation of a book.
enum ReflowStatus { pending, running, done, failed, noText }

/// Imported books. The id is the SHA-256 of the PDF bytes.
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get pageCount => integer()();
  DateTimeColumn get importedAt => dateTime()();
  TextColumn get reflowStatus => textEnum<ReflowStatus>().withDefault(
    Constant(ReflowStatus.pending.name),
  )();
  RealColumn get reflowProgress => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small key/value settings (reading settings, …).
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Where reading stopped, per book and view.
@DataClassName('ReadingPositionRow')
class ReadingPositions extends Table {
  TextColumn get bookId => text()();
  TextColumn get view => textEnum<ReadingView>()();
  IntColumn get page => integer()();
  TextColumn get blockId => text().nullable()();
  RealColumn get progress => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {bookId, view};
}

/// Highlights and notes (only in the app, never written into the PDF).
@DataClassName('AnnotationRow')
class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookId => text()();
  TextColumn get view => textEnum<ReadingView>()();
  IntColumn get page => integer()();
  IntColumn get start => integer()();
  IntColumn get end => integer()();
  TextColumn get quote => text()();
  TextColumn get color => textEnum<HighlightColor>()();
  TextColumn get note => text().nullable()();
  TextColumn get blockId => text().nullable()();
  TextColumn get prefix => text().withDefault(const Constant(''))();
  TextColumn get suffix => text().withDefault(const Constant(''))();
  IntColumn get engineVersion => integer().nullable()();
  BoolColumn get orphaned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Books, Preferences, ReadingPositions, Annotations])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  new defaults() : super(driftDatabase(name: 'unpaged'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Schema changes add steps here, one `if (from < n)` block per version.
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(preferences);
      if (from < 3) await m.createTable(readingPositions);
      if (from < 4) await m.createTable(annotations);
    },
  );

  /// All books, newest import first.
  Stream<List<Book>> watchBooks() => (select(
    books,
  )..orderBy([(b) => OrderingTerm.desc(b.importedAt)])).watch();

  Stream<Book?> watchBook(String id) =>
      (select(books)..where((b) => b.id.equals(id))).watchSingleOrNull();

  Future<Book?> bookById(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();
}

final StreamProviderFamily<Book?, String> bookProvider =
    StreamProvider.family<Book?, String>(
      (ref, id) => ref.watch(databaseProvider).watchBook(id),
    );

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});
