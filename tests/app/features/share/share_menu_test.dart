import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/core/platform/pdf_share_channel.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';
import 'package:unpaged/features/viewer/presentation/viewer_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

class _MockShare extends Mock implements PdfShareChannel;

void main() {
  late TestEnv env;
  late _MockAdapter adapter;
  late _MockShare share;

  setUp(() async {
    env = TestEnv();
    adapter = _MockAdapter();
    share = _MockShare();
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
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 1));
    when(() => share.share(any(), name: any(named: 'name')))
        .thenAnswer((_) async => true);
    when(() => share.print(any(), name: any(named: 'name')))
        .thenAnswer((_) async => true);
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
    await env.reflow.writeDocument(
      'abc',
      const ReflowDocument(
        engineVersion: ReflowEngine.version,
        blocks: [
          ReflowBlock(
            id: 'p1b0',
            type: BlockType.paragraph,
            text: 'Body text.',
            page: 1,
            box: BBox(0, 0, 1, 1),
          ),
        ],
      ),
    );
  });

  tearDown(() => env.dispose());

  List<dynamic> overrides() => [
    ...env.overrides,
    pdfAdapterProvider.overrideWithValue(adapter),
    pdfShareChannelProvider.overrideWithValue(share),
  ];

  String storedPath() => env.store.fileFor('abc').path;

  Future<void> pumpViewer(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: overrides(),
        locale: locale ?? const Locale('en'),
        home: ViewerScreen(path: storedPath(), title: 'Paper', bookId: 'abc'),
      ),
    );
    await settleIo(tester);
  }

  testWidgets('original view: "Share" sends the PDF with its title', (
    tester,
  ) async {
    await pumpViewer(tester);

    await tester.tap(find.byTooltip('Share or print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share PDF'));
    await settleIo(tester);

    verify(() => share.share(storedPath(), name: 'Paper.pdf')).called(1);
    await env.unmount(tester);
  });

  testWidgets('original view: "Print" opens the print dialog', (tester) async {
    await pumpViewer(tester);

    await tester.tap(find.byTooltip('Share or print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Print'));
    await settleIo(tester);

    verify(() => share.print(storedPath(), name: 'Paper.pdf')).called(1);
    await env.unmount(tester);
  });

  testWidgets('eBook view shares the original PDF', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: overrides(),
        home: const ReaderScreen(bookId: 'abc', title: 'Paper'),
      ),
    );
    await settleIo(tester);

    await tester.tap(find.byTooltip('Share or print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share PDF'));
    await settleIo(tester);

    verify(() => share.share(storedPath(), name: 'Paper.pdf')).called(1);
    await env.unmount(tester);
  });

  testWidgets('shows a localized hint when sharing is not possible', (
    tester,
  ) async {
    when(() => share.share(any(), name: any(named: 'name')))
        .thenAnswer((_) async => false);
    await pumpViewer(tester, locale: const Locale('de'));

    await tester.tap(find.byTooltip('Teilen oder drucken'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF teilen'));
    await settleIo(tester);

    expect(
      find.text('Keine App zum Teilen oder Drucken gefunden.'),
      findsOneWidget,
    );
    await env.unmount(tester);
  });
}
