import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Scaffold, Theme;
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/theme/app_theme.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';
import 'package:unpaged/features/settings/data/settings_repository.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';
import '../../helpers/text_style.dart';

const _doc = ReflowDocument(
  engineVersion: ReflowEngine.version,
  blocks: [
    ReflowBlock(
      id: 'p1b0',
      type: BlockType.paragraph,
      text: 'Body text here.',
      page: 1,
      box: BBox(0, 0, 1, 1),
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

  Future<void> pumpReader(WidgetTester tester) async {
    await tester.runAsync(() => env.reflow.writeDocument('abc', _doc));
    await tester.pumpWidget(
      buildTestApp(
        overrides: env.overrides,
        home: const ReaderScreen(bookId: 'abc', title: 'Paper'),
      ),
    );
    await settleIo(tester);
  }

  // Reader text is selectable since Task 11 (approved test adaptation).
  TextStyle bodyStyle(WidgetTester tester) =>
      readerTextStyle(tester, 'Body text here.');

  testWidgets('the reader uses the stored settings', (tester) async {
    await SettingsRepository(env.db).save(
      ReaderSettings.defaults.copyWith(font: ReaderFont.atkinson).biggerFont(),
    );
    await pumpReader(tester);

    expect(bodyStyle(tester).fontSize, 20);
    expect(bodyStyle(tester).fontFamily, 'AtkinsonHyperlegible');
    expect(bodyStyle(tester).height, 1.5);
    await env.unmount(tester);
  });

  testWidgets('a bigger font in the settings sheet applies at once', (
    tester,
  ) async {
    await pumpReader(tester);
    await tester.tap(find.byTooltip('Reading settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Larger text'));
    await settleIo(tester);

    expect(bodyStyle(tester).fontSize, 20);
    expect((await SettingsRepository(env.db).load()).fontSize, 20);
    await env.unmount(tester);
  });

  testWidgets('choosing sepia changes the reader background', (tester) async {
    await pumpReader(tester);
    await tester.tap(find.byTooltip('Reading settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sepia'));
    await settleIo(tester);

    final context = tester.element(find.text('Body text here.'));
    expect(Theme.of(context).scaffoldBackgroundColor, sepiaBackground);
    expect(find.byType(Scaffold), findsWidgets);
    await env.unmount(tester);
  });
}
