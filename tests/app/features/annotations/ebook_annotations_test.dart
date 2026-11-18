import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/annotations/data/annotation_repository.dart';
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

ReflowDocument _doc(List<(String, String)> blocks) => ReflowDocument(
  engineVersion: ReflowEngine.version,
  blocks: [
    for (final (id, text) in blocks)
      ReflowBlock(
        id: id,
        type: BlockType.paragraph,
        text: text,
        page: 1,
        box: const BBox(0, 0, 1, 1),
      ),
  ],
);

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
            pageCount: 1,
            importedAt: DateTime.utc(2026),
            reflowStatus: const Value(ReflowStatus.done),
          ),
        );
  });
  tearDown(() => env.dispose());

  Future<List<Annotation>> load(WidgetTester tester) async =>
      (await tester.runAsync(
        () =>
            AnnotationRepository(env.db).watch('abc', ReadingView.ebook).first,
      ))!;

  Future<void> pumpReader(WidgetTester tester, ReflowDocument doc) async {
    await tester.runAsync(() => env.reflow.writeDocument('abc', doc));
    await tester.pumpWidget(
      buildTestApp(
        overrides: env.overrides,
        home: const ReaderScreen(bookId: 'abc', title: 'Paper', initialPage: 1),
      ),
    );
    await settleIo(tester);
  }

  Future<void> select(WidgetTester tester, int start, int end) async {
    final state = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    state.userUpdateTextEditingValue(
      state.textEditingValue.copyWith(
        selection: TextSelection(baseOffset: start, extentOffset: end),
      ),
      SelectionChangedCause.longPress,
    );
    await tester.pump();
    state.showToolbar();
    await tester.pumpAndSettle();
  }

  testWidgets('highlighting a selection stores block id, offsets and quote', (
    tester,
  ) async {
    await pumpReader(tester, _doc([('p1b0', 'The quick brown fox jumps.')]));

    await select(tester, 4, 9);
    await tester.tap(find.text('Highlight'));
    await settleIo(tester);

    final a = (await load(tester)).single;
    expect(a.blockId, 'p1b0');
    expect((a.start, a.end), (4, 9));
    expect(a.quote, 'quick');
    expect(a.prefix, 'The ');
    expect(a.suffix, ' brown fox jumps.');
    expect(a.engineVersion, ReflowEngine.version);
    await env.unmount(tester);
  });

  testWidgets('Highlight and Add note come before Copy in the toolbar', (
    tester,
  ) async {
    // Android moves trailing items into the overflow menu; the highlight
    // actions must stay visible on a phone.
    await pumpReader(tester, _doc([('p1b0', 'The quick brown fox jumps.')]));

    await select(tester, 4, 9);

    final highlightX = tester.getTopLeft(find.text('Highlight')).dx;
    final noteX = tester.getTopLeft(find.text('Add note')).dx;
    final copyX = tester.getTopLeft(find.text('Copy')).dx;
    expect(highlightX, lessThan(noteX));
    expect(noteX, lessThan(copyX));
    await env.unmount(tester);
  });

  testWidgets('a stored highlight is drawn behind its text', (tester) async {
    await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.ebook,
        page: 1,
        blockId: 'p1b0',
        start: 4,
        end: 9,
        quote: 'quick',
        engineVersion: ReflowEngine.version,
      ),
    );
    await pumpReader(tester, _doc([('p1b0', 'The quick brown fox jumps.')]));

    final text = tester.widget<EditableText>(find.byType(EditableText).first);
    final spans = <TextSpan>[];
    text.controller
        .buildTextSpan(
          context: tester.element(find.byType(EditableText).first),
          withComposing: false,
        )
        .visitChildren((s) {
          if (s is TextSpan) spans.add(s);
          return true;
        });
    final highlighted = spans.where((s) => s.style?.backgroundColor != null);
    expect(highlighted.map((s) => s.text), ['quick']);
    await env.unmount(tester);
  });

  testWidgets('after a recomputation highlights follow their quote', (
    tester,
  ) async {
    await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.ebook,
        page: 1,
        blockId: 'p1b0',
        start: 4,
        end: 9,
        quote: 'quick',
        prefix: 'The ',
        suffix: ' brown fox',
        engineVersion: ReflowEngine.version - 1,
      ),
    );

    await pumpReader(
      tester,
      _doc([
        ('p1b0', 'A new first paragraph.'),
        ('p1b1', 'The quick brown fox jumps.'),
      ]),
    );

    final a = (await load(tester)).single;
    expect(a.blockId, 'p1b1');
    expect(a.engineVersion, ReflowEngine.version);
    expect(a.orphaned, isFalse);
    await env.unmount(tester);
  });

  testWidgets('a highlight whose quote is gone is kept as orphaned', (
    tester,
  ) async {
    await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.ebook,
        page: 1,
        blockId: 'p1b0',
        start: 0,
        end: 5,
        quote: 'Lorem',
        engineVersion: ReflowEngine.version - 1,
      ),
    );

    await pumpReader(tester, _doc([('p1b0', 'Completely different text.')]));

    final a = (await load(tester)).single;
    expect(a.orphaned, isTrue);

    await tester.tap(find.byTooltip('Highlights'));
    await tester.pumpAndSettle();
    expect(find.text('Not found in the current version'), findsOneWidget);
    await env.unmount(tester);
  });

  testWidgets('tapping inside a highlight opens it for editing', (
    tester,
  ) async {
    await AnnotationRepository(env.db).add(
      'abc',
      const AnnotationDraft(
        view: ReadingView.ebook,
        page: 1,
        blockId: 'p1b0',
        start: 4,
        end: 9,
        quote: 'quick',
        engineVersion: ReflowEngine.version,
      ),
    );
    await pumpReader(tester, _doc([('p1b0', 'The quick brown fox jumps.')]));

    final state = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    state.userUpdateTextEditingValue(
      state.textEditingValue.copyWith(
        selection: const TextSelection.collapsed(offset: 6),
      ),
      SelectionChangedCause.tap,
    );
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    await env.unmount(tester);
  });
}
