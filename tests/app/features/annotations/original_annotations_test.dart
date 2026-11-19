import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/features/annotations/data/annotation_repository.dart';
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';
import 'package:unpaged/features/viewer/presentation/viewer_screen.dart';

import '../../helpers/menu.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

void main() {
  late TestEnv env;
  late _MockAdapter adapter;
  late List<PageHighlight> shown;
  late List<SelectionAction> actions;
  late ValueChanged<int>? onHighlightTap;

  setUp(() async {
    env = TestEnv();
    adapter = _MockAdapter();
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 5));
    when(
      () => adapter.textRects(
        any(),
        page: any(named: 'page'),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const [BBox(10, 20, 110, 30)]);
    when(
      () => adapter.pageView(
        any(),
        controller: any(named: 'controller'),
        initialPage: any(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    ).thenAnswer((inv) {
      shown = inv.namedArguments[#highlights] as List<PageHighlight>;
      actions = inv.namedArguments[#selectionActions] as List<SelectionAction>;
      onHighlightTap =
          inv.namedArguments[#onHighlightTap] as ValueChanged<int>?;
      return Text('ORIGINAL with ${shown.length} highlights');
    });
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

  Future<void> pumpViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          ...env.overrides,
          pdfAdapterProvider.overrideWithValue(adapter),
        ],
        home: const ViewerScreen(
          path: '/b/abc.pdf',
          title: 'Paper',
          bookId: 'abc',
        ),
      ),
    );
    await settleIo(tester);
  }

  /// drift streams need real async; inside widget tests read via runAsync.
  Future<List<Annotation>> loadHighlights(WidgetTester tester) async =>
      (await tester.runAsync(
        () =>
            AnnotationRepository(env.db)
                .watch('abc', ReadingView.original)
                .first,
      ))!;

  const selection = PdfSelection(
    page: 2,
    start: 5,
    end: 17,
    text: 'chosen words',
  );

  testWidgets('"Highlight" on a selection stores and shows a highlight', (
    tester,
  ) async {
    await pumpViewer(tester);
    expect(find.text('ORIGINAL with 0 highlights'), findsOneWidget);

    actions.firstWhere((a) => a.label == 'Highlight').onSelected([selection]);
    await settleIo(tester);

    final stored = await loadHighlights(tester);
    expect(stored.single.page, 2);
    expect(stored.single.start, 5);
    expect(stored.single.end, 17);
    expect(stored.single.quote, 'chosen words');
    expect(find.text('ORIGINAL with 1 highlights'), findsOneWidget);
    expect(shown.single.page, 2);
    expect(shown.single.rects, const [BBox(10, 20, 110, 30)]);
    await env.unmount(tester);
  });

  testWidgets('"Add note" stores the highlight with the typed note', (
    tester,
  ) async {
    await pumpViewer(tester);

    actions.firstWhere((a) => a.label == 'Add note').onSelected([selection]);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Important!');
    await tester.tap(find.text('Save'));
    await settleIo(tester);

    final stored = await loadHighlights(tester);
    expect(stored.single.note, 'Important!');
    await env.unmount(tester);
  });

  testWidgets('tapping a highlight lets you edit its note or delete it', (
    tester,
  ) async {
    final id = await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.original,
        page: 2,
        start: 5,
        end: 17,
        quote: 'chosen words',
      ),
    );
    await pumpViewer(tester);

    onHighlightTap!(id);
    await tester.pumpAndSettle();
    expect(find.text('chosen words'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Edited');
    await tester.tap(find.text('Save'));
    await settleIo(tester);
    expect((await loadHighlights(tester)).single.note, 'Edited');

    onHighlightTap!(id);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settleIo(tester);
    expect(await loadHighlights(tester), isEmpty);
    await env.unmount(tester);
  });

  testWidgets('the highlights list jumps to the page of a highlight', (
    tester,
  ) async {
    await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.original,
        page: 4,
        start: 0,
        end: 3,
        quote: 'on page four',
        note: 'n',
      ),
    );
    await pumpViewer(tester);

    await chooseFromMenu(tester, 'Highlights');
    await tester.pumpAndSettle();
    await tester.tap(find.text('on page four'));
    await settleIo(tester);

    final call = verify(
      () => adapter.pageView(
        any(),
        controller: any(named: 'controller'),
        initialPage: captureAny(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    ).captured;
    expect(call.last, 4);
    await env.unmount(tester);
  });

  testWidgets('highlighting never changes the stored PDF file', (tester) async {
    final file = env.store.fileFor('abc');
    await tester.runAsync(() async {
      await file.parent.create(recursive: true);
      await file.writeAsString('%PDF-1.4 original bytes');
    });
    final before = sha256.convert(file.readAsBytesSync());
    await pumpViewer(tester);

    actions.firstWhere((a) => a.label == 'Highlight').onSelected([selection]);
    await settleIo(tester);

    expect(sha256.convert(file.readAsBytesSync()), before);
    await env.unmount(tester);
  });
}
