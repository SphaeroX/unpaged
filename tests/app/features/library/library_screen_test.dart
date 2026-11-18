import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockAdapter extends Mock implements PdfAdapter;

void main() {
  late TestEnv env;
  late _MockAdapter adapter;

  setUp(() {
    env = TestEnv();
    adapter = _MockAdapter();
    when(() => adapter.pageView(any()))
        .thenAnswer((inv) => Text('pages:${inv.positionalArguments.first}'));
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 3));
  });

  tearDown(() => env.dispose());

  Future<void> addBook(String id, String title, int pages) => env.db
      .into(env.db.books)
      .insert(
        BooksCompanion.insert(
          id: id,
          title: title,
          pageCount: pages,
          importedAt: DateTime.utc(2026),
        ),
      );

  List<dynamic> overrides() => [
    ...env.overrides,
    pdfAdapterProvider.overrideWithValue(adapter),
  ];

  testWidgets('shows an empty state without books', (tester) async {
    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await settleIo(tester);

    expect(find.text('No books yet. Open a PDF to start.'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('lists books with title and page count', (tester) async {
    await addBook('a', 'Paper One', 12);
    await addBook('b', 'Paper Two', 1);

    await tester.pumpWidget(
      buildTestApp(overrides: overrides(), locale: const Locale('de')),
    );
    await settleIo(tester);

    expect(find.text('Paper One'), findsOneWidget);
    expect(find.text('12 Seiten'), findsOneWidget);
    expect(find.text('1 Seite'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('tapping a book opens its stored copy', (tester) async {
    await addBook('abc', 'Paper One', 12);

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await settleIo(tester);
    await tester.tap(find.text('Paper One'));
    await settleIo(tester);

    expect(find.text('pages:${env.store.fileFor('abc').path}'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('delete asks first; cancel keeps the book', (tester) async {
    await addBook('abc', 'Paper One', 12);

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await settleIo(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete “Paper One”?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleIo(tester);

    expect(find.text('Paper One'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('confirming delete removes the book', (tester) async {
    await addBook('abc', 'Paper One', 12);

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await settleIo(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settleIo(tester);

    expect(find.text('Paper One'), findsNothing);
    expect(await env.db.select(env.db.books).get(), isEmpty);

    await env.unmount(tester);
  });
}
