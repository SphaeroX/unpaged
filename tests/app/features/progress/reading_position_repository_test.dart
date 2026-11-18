import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/progress/data/reading_position_repository.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';

void main() {
  late AppDatabase db;
  late ReadingPositionRepository repo;
  var now = DateTime.utc(2026);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ReadingPositionRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('stores one position per book and view', () async {
    await repo.save(
      'abc',
      const ReadingPosition(
        view: ReadingView.original,
        page: 3,
        progress: 0.25,
      ),
    );
    await repo.save(
      'abc',
      const ReadingPosition(
        view: ReadingView.ebook,
        page: 4,
        blockId: 'p4b0',
        progress: 0.5,
      ),
    );
    await repo.save(
      'abc',
      const ReadingPosition(view: ReadingView.original, page: 5, progress: 0.4),
    );

    expect((await repo.load('abc', ReadingView.original))!.page, 5);
    expect((await repo.load('abc', ReadingView.ebook))!.blockId, 'p4b0');
    expect(await repo.load('other', ReadingView.ebook), isNull);
  });

  test('lastUsed returns the most recently saved view', () async {
    await repo.save(
      'abc',
      const ReadingPosition(view: ReadingView.ebook, page: 1, progress: 0.1),
    );
    now = now.add(const Duration(minutes: 1));
    await repo.save(
      'abc',
      const ReadingPosition(view: ReadingView.original, page: 2, progress: 0.2),
    );

    expect((await repo.lastUsed('abc'))!.view, ReadingView.original);
  });

  test('watchProgress maps each book to its latest progress', () async {
    await repo.save(
      'a',
      const ReadingPosition(
        view: ReadingView.original,
        page: 3,
        progress: 0.25,
      ),
    );
    await repo.save(
      'b',
      const ReadingPosition(view: ReadingView.ebook, page: 1, progress: 0.75),
    );

    expect(await repo.watchProgress().first, {'a': 0.25, 'b': 0.75});
  });

  test('deleting a book removes its positions', () async {
    await repo.save(
      'a',
      const ReadingPosition(
        view: ReadingView.original,
        page: 3,
        progress: 0.25,
      ),
    );

    await repo.deleteBook('a');

    expect(await repo.lastUsed('a'), isNull);
  });
}
