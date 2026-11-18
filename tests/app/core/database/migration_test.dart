import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:unpaged/core/database/app_database.dart';

/// A database file as written by schema version 1 (Task 05).
sqlite.Database _version1() {
  final raw = sqlite.sqlite3.openInMemory()
    ..execute('''
      CREATE TABLE books (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        page_count INTEGER NOT NULL,
        imported_at INTEGER NOT NULL,
        reflow_status TEXT NOT NULL DEFAULT 'pending',
        reflow_progress REAL NOT NULL DEFAULT 0.0
      );
    ''')
    ..execute(
      "INSERT INTO books VALUES ('abc', 'Paper', 3, 1700000000, 'done', 1.0);",
    )
    ..userVersion = 1;
  return raw;
}

void main() {
  test('upgrading from version 1 keeps books and adds new tables', () async {
    final db = AppDatabase(NativeDatabase.opened(_version1()));
    addTearDown(db.close);

    final books = await db.select(db.books).get();
    expect(books.single.title, 'Paper');
    expect(books.single.reflowStatus, ReflowStatus.done);
    expect(await db.select(db.preferences).get(), isEmpty);
    expect(await db.select(db.readingPositions).get(), isEmpty);
    expect(await db.select(db.annotations).get(), isEmpty);
    expect(db.schemaVersion, greaterThanOrEqualTo(4));
  });

  test('upgrading from version 2 keeps settings', () async {
    final raw = _version1()
      ..execute(
        'CREATE TABLE preferences (key TEXT NOT NULL PRIMARY KEY, '
        'value TEXT NOT NULL);',
      )
      ..execute("INSERT INTO preferences VALUES ('reader.theme', 'dark');")
      ..userVersion = 2;
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect((await db.select(db.preferences).get()).single.value, 'dark');
    expect(await db.select(db.readingPositions).get(), isEmpty);
  });
}
