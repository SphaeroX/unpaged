import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/annotations/data/annotation_repository.dart';
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';

void main() {
  late AppDatabase db;
  late AnnotationRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AnnotationRepository(db, clock: () => DateTime.utc(2026));
  });
  tearDown(() => db.close());

  const draft = AnnotationDraft(
    view: ReadingView.original,
    page: 2,
    start: 10,
    end: 25,
    quote: 'selected words',
  );

  test('adds, lists, edits and deletes highlights of a book', () async {
    final id = await repo.add('abc', draft);

    var list = await repo.watch('abc', ReadingView.original).first;
    expect(list.single.id, id);
    expect(list.single.page, 2);
    expect(list.single.color, HighlightColor.yellow);
    expect(list.single.note, isNull);

    await repo.update(id, note: 'my note', color: HighlightColor.green);
    list = await repo.watch('abc', ReadingView.original).first;
    expect(list.single.note, 'my note');
    expect(list.single.color, HighlightColor.green);

    await repo.delete(id);
    expect(await repo.watch('abc', ReadingView.original).first, isEmpty);
  });

  test('keeps views apart', () async {
    await repo.add('abc', draft);

    expect(await repo.watch('abc', ReadingView.ebook).first, isEmpty);
  });

  test('lists highlights in reading order (page, then start)', () async {
    await repo.add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.original,
        page: 3,
        start: 0,
        end: 4,
        quote: 'c',
      ),
    );
    await repo.add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.original,
        page: 1,
        start: 9,
        end: 12,
        quote: 'b',
      ),
    );
    await repo.add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.original,
        page: 1,
        start: 2,
        end: 5,
        quote: 'a',
      ),
    );

    final quotes = (await repo.watch('abc', ReadingView.original).first).map(
      (a) => a.quote,
    );
    expect(quotes, ['a', 'b', 'c']);
  });

  test('deleteBook removes all highlights of the book', () async {
    await repo.add('abc', draft);
    await repo.deleteBook('abc');

    expect(await repo.watch('abc', ReadingView.original).first, isEmpty);
  });
}
