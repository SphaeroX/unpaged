import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/progress/data/reading_position_repository.dart';
import 'package:paperflow/features/progress/domain/reading_position.dart';
import 'package:paperflow/features/reader/presentation/reader_screen.dart';
import 'package:paperflow/features/viewer/presentation/viewer_screen.dart';
import 'package:reflow_engine/reflow_engine.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

/// Ten tall blocks per page on pages 1–5.
final _doc = ReflowDocument(
  engineVersion: ReflowEngine.version,
  blocks: [
    for (var p = 1; p <= 5; p++)
      for (var i = 0; i < 10; i++)
        ReflowBlock(
          id: 'p${p}b$i',
          type: BlockType.paragraph,
          text: 'Block $i on page $p. ${'Filler text. ' * 20}',
          page: p,
          box: const BBox(0, 0, 1, 1),
        ),
  ],
);

void main() {
  late TestEnv env;
  late _MockAdapter adapter;
  void Function(int)? onPageChanged;
  int? shownPage;

  setUp(() async {
    env = TestEnv();
    adapter = _MockAdapter();
    when(
      () => adapter.pageView(
        any(),
        initialPage: any(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    ).thenAnswer((inv) {
      shownPage = inv.namedArguments[#initialPage] as int;
      onPageChanged = inv.namedArguments[#onPageChanged] as void Function(int)?;
      return Text('ORIGINAL page $shownPage');
    });
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 5));
    await env.db
        .into(env.db.books)
        .insert(
          BooksCompanion.insert(
            id: 'abc',
            title: 'Paper',
            pageCount: 5,
            importedAt: DateTime.utc(2026),
            reflowStatus: const Value(ReflowStatus.done),
          ),
        );
  });
  tearDown(() => env.dispose());

  List<dynamic> overrides() => [
    ...env.overrides,
    pdfAdapterProvider.overrideWithValue(adapter),
  ];

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.runAsync(() => env.reflow.writeDocument('abc', _doc));
    await tester.pumpWidget(buildTestApp(overrides: overrides(), home: home));
    await settleIo(tester);
  }

  bool isAtTop(WidgetTester tester, String text) {
    final top = tester.getTopLeft(find.textContaining(text)).dy;
    return top > 0 && top < 160; // just below the app bar
  }

  testWidgets('the reader opens at the first block of a given page', (
    tester,
  ) async {
    await pump(
      tester,
      const ReaderScreen(bookId: 'abc', title: 'Paper', initialPage: 3),
    );

    expect(isAtTop(tester, 'Block 0 on page 3.'), isTrue);
    await env.unmount(tester);
  });

  testWidgets('switching from page 4 of the original opens the eBook there', (
    tester,
  ) async {
    await pump(
      tester,
      const ViewerScreen(path: '/b/abc.pdf', title: 'Paper', bookId: 'abc'),
    );
    onPageChanged!(4);
    await settleIo(tester);

    await tester.tap(find.byTooltip('eBook view'));
    await settleIo(tester);

    expect(isAtTop(tester, 'Block 0 on page 4.'), isTrue);
    await env.unmount(tester);
  });

  testWidgets("switching back opens the original at the block's page", (
    tester,
  ) async {
    await pump(
      tester,
      const ReaderScreen(bookId: 'abc', title: 'Paper', initialPage: 2),
    );

    await tester.tap(find.byTooltip('Original view'));
    await settleIo(tester);

    expect(find.text('ORIGINAL page 2'), findsOneWidget);
    await env.unmount(tester);
  });

  testWidgets('page changes in the original are saved', (tester) async {
    await pump(
      tester,
      const ViewerScreen(path: '/b/abc.pdf', title: 'Paper', bookId: 'abc'),
    );

    onPageChanged!(3);
    await settleIo(tester);

    final saved = await ReadingPositionRepository(env.db)
        .load('abc', ReadingView.original);
    expect(saved!.page, 3);
    expect(saved.progress, closeTo(0.6, 1e-9));
    await env.unmount(tester);
  });

  testWidgets('scrolling the eBook saves the top block', (tester) async {
    await pump(
      tester,
      const ReaderScreen(bookId: 'abc', title: 'Paper', initialPage: 1),
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await settleIo(tester);

    final saved = await ReadingPositionRepository(env.db)
        .load('abc', ReadingView.ebook);
    expect(saved, isNotNull);
    expect(saved!.blockId, isNot('p1b0'));
    await env.unmount(tester);
  });

  testWidgets('without a page the reader resumes at the saved block', (
    tester,
  ) async {
    await ReadingPositionRepository(env.db).save(
      'abc',
      const ReadingPosition(
        view: ReadingView.ebook,
        page: 5,
        blockId: 'p5b3',
        progress: 0.9,
      ),
    );

    await pump(tester, const ReaderScreen(bookId: 'abc', title: 'Paper'));

    expect(isAtTop(tester, 'Block 3 on page 5.'), isTrue);
    await env.unmount(tester);
  });
}
