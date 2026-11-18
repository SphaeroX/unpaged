import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  BooksCompanion book(String id, {String title = 'Title'}) =>
      BooksCompanion.insert(
        id: id,
        title: title,
        pageCount: 3,
        importedAt: DateTime.utc(2026, 11, 18),
      );

  test('stores and reads a book', () async {
    await db.into(db.books).insert(book('abc', title: 'Paper'));

    final books = await db.select(db.books).get();

    expect(books.single.id, 'abc');
    expect(books.single.title, 'Paper');
    expect(books.single.reflowStatus, ReflowStatus.pending);
    expect(books.single.reflowProgress, 0);
  });

  test('rejects a second book with the same id (sha256)', () async {
    await db.into(db.books).insert(book('abc'));

    await expectLater(
      db.into(db.books).insert(book('abc')),
      throwsA(isA<Exception>()),
    );
  });

  test('watchBooks lists newest imports first', () async {
    await db
        .into(db.books)
        .insert(book('old').copyWith(importedAt: Value(DateTime.utc(2026))));
    await db
        .into(db.books)
        .insert(
          book('new').copyWith(importedAt: Value(DateTime.utc(2026, 12))),
        );

    final books = await db.watchBooks().first;

    expect(books.map((b) => b.id), ['new', 'old']);
  });
}
