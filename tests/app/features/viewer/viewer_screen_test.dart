import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/features/viewer/presentation/viewer_screen.dart';

import '../../helpers/menu.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

void main() {
  late TestEnv env;
  late _MockAdapter adapter;
  late List<int> jumps;
  late List<PageHighlight> shown;
  PageViewController? controller;

  setUp(() async {
    env = TestEnv();
    adapter = _MockAdapter();
    jumps = [];
    shown = [];
    controller = null;
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
      controller = inv.namedArguments[#controller] as PageViewController?;
      controller?.goToHandler = (page) async => jumps.add(page);
      shown = inv.namedArguments[#highlights] as List<PageHighlight>;
      return const Text('ORIGINAL');
    });
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 3));
    when(() => adapter.pageTexts(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        PageText(page: 1, text: 'Nothing here.'),
        PageText(page: 2, text: 'The black cat.'),
      ]),
    );
    when(
      () => adapter.textRects(
        any(),
        page: any(named: 'page'),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) async => const [BBox(10, 20, 30, 28)]);
    await env.db
        .into(env.db.books)
        .insert(
          BooksCompanion.insert(
            id: 'abc',
            title: 'Paper',
            pageCount: 3,
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
        home: ViewerScreen(
          path: env.store.fileFor('abc').path,
          title: 'Paper',
          bookId: 'abc',
        ),
      ),
    );
    await settleIo(tester);
  }

  testWidgets('the app bar shows only the GitHub link and the ⋮ menu', (
    tester,
  ) async {
    await pumpViewer(tester);

    final bar = find.byType(AppBar);
    expect(
      find.descendant(of: bar, matching: find.byType(IconButton)),
      findsNWidgets(2),
    );
    expect(find.byTooltip('Unpaged on GitHub'), findsOneWidget);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    for (final label in [
      'Search',
      'Highlights',
      'eBook view',
      'Share PDF',
      'Print',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await env.unmount(tester);
  });

  testWidgets('the page view gets a controller for fast scrolling', (
    tester,
  ) async {
    await pumpViewer(tester);

    expect(controller, isNotNull);
    await env.unmount(tester);
  });

  testWidgets('search jumps to the page of the hit and marks it', (
    tester,
  ) async {
    await pumpViewer(tester);

    await chooseFromMenu(tester, 'Search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'cat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settleIo(tester);
    await tester.tap(find.text('Page 2'));
    await settleIo(tester);

    expect(find.text('ORIGINAL'), findsOneWidget);
    expect(jumps, [2]);
    verify(
      () => adapter.textRects(
        env.store.fileFor('abc').path,
        page: 2,
        start: 10,
        end: 13,
      ),
    ).called(1);
    final mark = shown.singleWhere((h) => h.page == 2);
    expect(mark.rects, const [BBox(10, 20, 30, 28)]);
    await env.unmount(tester);
  });
}
