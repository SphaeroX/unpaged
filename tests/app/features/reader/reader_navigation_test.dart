import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';

import '../../helpers/menu.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

/// 60 paragraphs on 30 pages; the last one holds a unique word.
final _doc = ReflowDocument(
  engineVersion: ReflowEngine.version,
  blocks: [
    for (var i = 0; i < 60; i++)
      ReflowBlock(
        id: 'b$i',
        type: BlockType.paragraph,
        text: i == 59 ? 'The hidden treasure.' : 'Paragraph $i of the book.',
        page: i ~/ 2 + 1,
        box: const BBox(0, 0, 1, 1),
      ),
  ],
);

/// Text spans of the reader block showing [text] that have a background.
List<String> markedIn(WidgetTester tester, String text) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is SelectableText && w.textSpan!.toPlainText() == text,
      ),
      matching: find.byType(EditableText),
    ),
  );
  final marked = <String>[];
  void walk(InlineSpan s) {
    if (s is TextSpan && s.text != null && s.style?.backgroundColor != null) {
      marked.add(s.text!);
    }
    s.visitDirectChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(
    editable.controller.buildTextSpan(
      context: tester.element(find.byWidget(editable)),
      withComposing: false,
    ),
  );
  return marked;
}

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.db
        .into(env.db.books)
        .insert(
          BooksCompanion.insert(
            id: 'abc',
            title: 'Paper',
            pageCount: 30,
            importedAt: DateTime.utc(2026),
            reflowStatus: const Value(ReflowStatus.done),
          ),
        );
  });

  tearDown(() => env.dispose());

  Future<void> pumpReader(WidgetTester tester) async {
    await tester.runAsync(() => env.reflow.writeDocument('abc', _doc));
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          ...env.overrides,
          pdfAdapterProvider.overrideWithValue(_MockAdapter()),
        ],
        home: const ReaderScreen(bookId: 'abc', title: 'Paper'),
      ),
    );
    await settleIo(tester);
  }

  testWidgets('the app bar shows only the GitHub link and the ⋮ menu', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
      findsNWidgets(2),
    );
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    for (final label in [
      'Search',
      'Highlights',
      'Reading settings',
      'Original view',
      'Share PDF',
      'Print',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await env.unmount(tester);
  });

  testWidgets('search jumps to the block of the hit and marks the word', (
    tester,
  ) async {
    await pumpReader(tester);
    expect(find.text('The hidden treasure.'), findsNothing);

    await chooseFromMenu(tester, 'Search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TREASURE');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Page 30'));
    await settleIo(tester);

    expect(find.text('The hidden treasure.'), findsOneWidget);
    expect(markedIn(tester, 'The hidden treasure.'), ['treasure']);
    await env.unmount(tester);
  });

  testWidgets('dragging the fast-scroll thumb to the bottom shows the end', (
    tester,
  ) async {
    await pumpReader(tester);
    expect(find.text('Paragraph 0 of the book.'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('fast-scroll-thumb')),
      const Offset(0, 2000),
    );
    await settleIo(tester);

    expect(find.text('The hidden treasure.'), findsOneWidget);
    expect(find.text('Paragraph 0 of the book.'), findsNothing);
    await env.unmount(tester);
  });

  testWidgets('the thumb shows the page while dragging', (tester) async {
    await pumpReader(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('fast-scroll-thumb'))),
    );
    await gesture.moveBy(const Offset(0, 2000));
    await tester.pump();

    expect(find.text('Page 30'), findsOneWidget);
    await gesture.up();
    await settleIo(tester);
    await env.unmount(tester);
  });
}
