import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/reflow/domain/reflow_pipeline.dart';
import 'package:unpaged/features/reflow/domain/reflow_scheduler.dart';

class _MockPipeline extends Mock implements ReflowPipeline;

class _FakeBook extends Fake implements Book;

void main() {
  late AppDatabase db;
  late _MockPipeline pipeline;
  late List<String> processed;

  setUpAll(() => registerFallbackValue(_FakeBook()));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pipeline = _MockPipeline();
    processed = [];
    when(() => pipeline.process(any())).thenAnswer((inv) async {
      processed.add(inv.positionalArguments.first as String);
    });
    for (final (id, day) in [('old', 1), ('new', 2), ('done', 3)]) {
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              id: id,
              title: id,
              pageCount: 1,
              importedAt: DateTime.utc(2026, 1, day),
            ),
          );
    }
    when(() => pipeline.needsWork(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as Book).id != 'done',
    );
  });

  tearDown(() => db.close());

  test('start() processes every book that needs work, oldest first', () async {
    final scheduler = ReflowScheduler(db: db, pipeline: pipeline);

    await scheduler.start();
    await scheduler.idle;

    expect(processed, ['old', 'new']);
  });

  test('enqueue() processes a book once, even if queued twice', () async {
    final scheduler = ReflowScheduler(db: db, pipeline: pipeline)
      ..enqueue('new')
      ..enqueue('new');

    await scheduler.idle;

    expect(processed, ['new']);
  });

  test('books queued while running are processed afterwards', () async {
    // The second book is queued while the first one is already running.
    final scheduler = ReflowScheduler(db: db, pipeline: pipeline)
      ..enqueue('old')
      ..enqueue('new');

    await scheduler.idle;

    expect(processed, ['old', 'new']);
  });
}
