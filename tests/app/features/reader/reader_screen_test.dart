import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/reader/presentation/reader_screen.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';
import 'package:paperflow/features/reflow/domain/reflow_scheduler.dart';
import 'package:paperflow/features/viewer/presentation/viewer_screen.dart';
import 'package:reflow_engine/reflow_engine.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

class _MockQueue extends Mock implements ReflowQueue;

const _doc = ReflowDocument(
  engineVersion: ReflowEngine.version,
  blocks: [
    ReflowBlock(
      id: 'p1b0',
      type: BlockType.heading,
      level: 1,
      text: 'Big Title',
      page: 1,
      box: BBox(0, 0, 1, 1),
    ),
    ReflowBlock(
      id: 'p1b1',
      type: BlockType.paragraph,
      text: 'Body text here.',
      page: 1,
      box: BBox(0, 2, 1, 3),
    ),
    ReflowBlock(
      id: 'p1b2',
      type: BlockType.listItem,
      text: '• An item',
      page: 1,
      box: BBox(0, 4, 1, 5),
    ),
    ReflowBlock(
      id: 'p1b3',
      type: BlockType.figure,
      text: '',
      page: 1,
      box: BBox(0, 6, 1, 7),
    ),
    ReflowBlock(
      id: 'p1b4',
      type: BlockType.caption,
      text: 'Figure 1: A caption.',
      page: 1,
      box: BBox(0, 8, 1, 9),
    ),
  ],
);

void main() {
  late TestEnv env;
  late ReflowStore store;
  late _MockAdapter adapter;
  late _MockQueue queue;

  setUp(() async {
    env = TestEnv();
    store = env.reflow;
    adapter = _MockAdapter();
    queue = _MockQueue();
    when(
      () => adapter.pageView(
        any(),
        initialPage: any(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    ).thenAnswer((_) => const Text('ORIGINAL'));
    await env.db
        .into(env.db.books)
        .insert(
          BooksCompanion.insert(
            id: 'abc',
            title: 'Paper',
            pageCount: 1,
            importedAt: DateTime.utc(2026),
            reflowStatus: const Value(ReflowStatus.done),
          ),
        );
  });

  tearDown(() => env.dispose());

  List<dynamic> overrides() => [
    ...env.overridesWith(queue: queue),
    pdfAdapterProvider.overrideWithValue(adapter),
  ];

  Future<void> pumpReader(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: overrides(),
        home: const ReaderScreen(bookId: 'abc', title: 'Paper'),
      ),
    );
    await settleIo(tester);
  }

  double fontSizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.fontSize!;

  testWidgets('shows each block type with its own style', (tester) async {
    await tester.runAsync(() => store.writeDocument('abc', _doc));
    await pumpReader(tester);

    expect(find.text('Big Title'), findsOneWidget);
    expect(find.text('Body text here.'), findsOneWidget);
    expect(find.text('• An item'), findsOneWidget);
    expect(
      fontSizeOf(tester, 'Big Title'),
      greaterThan(fontSizeOf(tester, 'Body text here.')),
    );
    expect(
      tester.widget<Text>(find.text('Figure 1: A caption.')).style!.fontStyle,
      FontStyle.italic,
    );
    await env.unmount(tester);
  });

  testWidgets('a region shows its crop; tapping opens a zoom view', (
    tester,
  ) async {
    await tester.runAsync(() => store.writeDocument('abc', _doc));
    await pumpReader(tester);

    final crop = find.byKey(const ValueKey('crop-p1b3'));
    expect(crop, findsOneWidget);
    await tester.tap(crop);
    await settleIo(tester);

    expect(find.byType(InteractiveViewer), findsOneWidget);
    await env.unmount(tester);
  });

  testWidgets('a missing document offers to prepare it again', (tester) async {
    await pumpReader(tester);

    expect(
      find.text('The eBook version is missing or damaged.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Prepare again'));
    await settleIo(tester);

    verify(() => queue.enqueue('abc')).called(1);
    final book = await env.db.bookById('abc');
    expect(book!.reflowStatus, ReflowStatus.pending);
    await env.unmount(tester);
  });

  group('switching views', () {
    Future<void> pumpViewer(WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          overrides: overrides(),
          home: const ViewerScreen(
            path: '/books/abc.pdf',
            title: 'Paper',
            bookId: 'abc',
          ),
        ),
      );
      await settleIo(tester);
    }

    testWidgets('original → eBook → original', (tester) async {
      when(() => adapter.inspect(any()))
          .thenAnswer((_) async => const PdfInfo(pageCount: 1));
      await tester.runAsync(() => store.writeDocument('abc', _doc));
      await pumpViewer(tester);
      expect(find.text('ORIGINAL'), findsOneWidget);

      await tester.tap(find.byTooltip('eBook view'));
      await settleIo(tester);
      expect(find.text('Body text here.'), findsOneWidget);

      await tester.tap(find.byTooltip('Original view'));
      await settleIo(tester);
      expect(find.text('ORIGINAL'), findsOneWidget);
      await env.unmount(tester);
    });

    testWidgets('the eBook view is not offered while preparing', (
      tester,
    ) async {
      when(() => adapter.inspect(any()))
          .thenAnswer((_) async => const PdfInfo(pageCount: 1));
      await env.db
          .update(env.db.books)
          .write(
            const BooksCompanion(
              reflowStatus: Value(ReflowStatus.running),
              reflowProgress: Value(0.5),
            ),
          );
      await pumpViewer(tester);

      await tester.tap(find.byTooltip('eBook view'));
      await settleIo(tester);

      expect(find.text('Preparing eBook … 50 %'), findsOneWidget);
      expect(find.text('ORIGINAL'), findsOneWidget);
      await env.unmount(tester);
    });
  });
}
