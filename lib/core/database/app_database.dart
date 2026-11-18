import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

@DriftDatabase(tables: [Books])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  new defaults() : super(driftDatabase(name: 'paperflow'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Schema changes add steps here, one `if (from < n)` block per version.
    onUpgrade: (m, from, to) async {},
  );

  /// All books, newest import first.
  Stream<List<Book>> watchBooks() => (select(
    books,
  )..orderBy([(b) => OrderingTerm.desc(b.importedAt)])).watch();

  Future<Book?> bookById(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});
