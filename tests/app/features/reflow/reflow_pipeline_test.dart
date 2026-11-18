import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/features/reflow/data/reflow_store.dart';
import 'package:unpaged/features/reflow/domain/reflow_pipeline.dart';

class _MockAdapter extends Mock implements PdfAdapter;

DocumentInput _input({int chars = 200}) => DocumentInput(
  pages: [
    PageInput(
      number: 1,
      width: 600,
      height: 800,
      chars: [
        for (var i = 0; i < chars; i++)
          TextChar(
            text: 'a',
            box: BBox(
              i % 100 * 5.0,
              100.0 + i ~/ 100 * 12,
              i % 100 * 5.0 + 4,
              107.0 + i ~/ 100 * 12,
            ),
          ),
      ],
    ),
  ],
);

const _regionDoc = ReflowDocument(
  engineVersion: 3,
  blocks: [
    ReflowBlock(
      id: 'p1b0',
      type: BlockType.paragraph,
      text: 'T',
      page: 1,
      box: BBox(0, 0, 1, 1),
    ),
    ReflowBlock(
      id: 'p1b1',
      type: BlockType.table,
      text: '',
      page: 1,
      box: BBox(10, 20, 110, 220),
    ),
  ],
);

void main() {
  late AppDatabase db;
  late Directory dir;
  late ReflowStore reflowStore;
  late BookFileStore books;
  late _MockAdapter adapter;

  setUpAll(() => registerFallbackValue(<RegionRequest>[]));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('unpaged_pipe');
    reflowStore = ReflowStore(dir);
    books = BookFileStore(dir);
    adapter = _MockAdapter();
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: 'abc',
            title: 'T',
            pageCount: 1,
            importedAt: DateTime.utc(2026),
          ),
        );
    when(() => adapter.extractText(any())).thenAnswer((_) async => _input());
    when(() => adapter.renderRegions(any(), any())).thenAnswer(
      (inv) async => [
        for (final _ in inv.positionalArguments[1] as List<RegionRequest>)
          Uint8List.fromList([9]),
      ],
    );
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  ReflowPipeline pipeline({EngineRunner? engine}) => ReflowPipeline(
    db: db,
    books: books,
    store: reflowStore,
    adapter: adapter,
    runEngine: engine ?? (input) async => _regionDoc,
  );

  Future<Book> book() async => (await db.bookById('abc'))!;

  test(
    'a successful run stores the document and marks the book done',
    () async {
      await pipeline().process('abc');

      expect((await book()).reflowStatus, ReflowStatus.done);
      expect((await book()).reflowProgress, 1);
      expect(await reflowStore.readDocument('abc'), _regionDoc);
    },
  );

  test('renders one crop per region block at its page and box', () async {
    await pipeline().process('abc');

    final requests =
        verify(
              () => adapter.renderRegions(
                books.fileFor('abc').path,
                captureAny(),
              ),
            ).captured.single
            as List<RegionRequest>;
    expect(requests.single.page, 1);
    expect(requests.single.box, const BBox(10, 20, 110, 220));
    expect(reflowStore.cropFile('abc', 'p1b1').readAsBytesSync(), [9]);
  });

  test('an engine error marks the book failed', () async {
    await pipeline(engine: (_) async => throw StateError('boom'))
        .process('abc');

    expect((await book()).reflowStatus, ReflowStatus.failed);
    expect(await reflowStore.readDocument('abc'), isNull);
  });

  test('a PDF without a text layer is marked noText', () async {
    when(() => adapter.extractText(any()))
        .thenAnswer((_) async => _input(chars: 3));

    await pipeline().process('abc');

    expect((await book()).reflowStatus, ReflowStatus.noText);
  });

  test('reports progress while running', () async {
    final seen = <double>[];
    final sub = db.watchBooks().listen(
      (b) => seen.add(b.single.reflowProgress),
    );

    await pipeline().process('abc');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(seen.where((p) => p > 0 && p < 1), isNotEmpty);
  });

  group('needsWork', () {
    test('pending and interrupted (running) books need work', () async {
      expect(await pipeline().needsWork(await book()), isTrue);
      await db
          .update(db.books)
          .write(
            const BooksCompanion(reflowStatus: Value(ReflowStatus.running)),
          );
      expect(await pipeline().needsWork(await book()), isTrue);
    });

    test('a done book with the current engine version needs no work', () async {
      await pipeline(
        engine: (_) async => const ReflowDocument(
          engineVersion: ReflowEngine.version,
          blocks: [],
        ),
      ).process('abc');

      expect(await pipeline().needsWork(await book()), isFalse);
    });

    test('a done book with an older engine version needs work', () async {
      await pipeline(
        engine: (_) async => const ReflowDocument(
          engineVersion: ReflowEngine.version - 1,
          blocks: [],
        ),
      ).process('abc');

      expect(await pipeline().needsWork(await book()), isTrue);
    });

    test('failed and noText books are not retried automatically', () async {
      await db
          .update(db.books)
          .write(
            const BooksCompanion(reflowStatus: Value(ReflowStatus.failed)),
          );
      expect(await pipeline().needsWork(await book()), isFalse);
    });
  });
}
