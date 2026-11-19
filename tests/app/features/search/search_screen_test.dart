import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/features/search/domain/text_search.dart';
import 'package:unpaged/features/search/presentation/search_screen.dart';

import '../../helpers/test_app.dart';

SearchHit _hit(int page, String text, int start, int end) => SearchHit(
  page: page,
  match: TextMatch(start, end),
  snippet: snippetAround(text, TextMatch(start, end)),
);

void main() {
  /// Opens the search from a button and records what it returns.
  Future<List<SearchHit?>> open(
    WidgetTester tester,
    Stream<SearchHit> Function(String query) search, {
    Locale locale = const Locale('en'),
  }) async {
    final results = <SearchHit?>[];
    await tester.pumpWidget(
      buildTestApp(
        locale: locale,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await SearchScreen.show(context, search: search)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('lists the hits with their page and returns the tapped one', (
    tester,
  ) async {
    final queries = <String>[];
    final hit = _hit(3, 'the black cat sleeps', 10, 13);
    final results = await open(tester, (q) {
      queries.add(q);
      return Stream.fromIterable([hit, _hit(7, 'cat', 0, 3)]);
    });

    await tester.enterText(find.byType(TextField), 'cat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(queries, ['cat']);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('Page 7'), findsOneWidget);
    expect(find.textContaining('the black cat sleeps'), findsOneWidget);

    await tester.tap(find.text('Page 3'));
    await tester.pumpAndSettle();

    expect(results, [hit]);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('says so when nothing is found (German)', (tester) async {
    await open(tester, (_) => const Stream.empty(), locale: const Locale('de'));

    await tester.enterText(find.byType(TextField), 'nichts');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Keine Treffer.'), findsOneWidget);
  });

  testWidgets('shows progress while searching and the hint at the limit', (
    tester,
  ) async {
    final hits = StreamController<SearchHit>();
    await open(tester, (_) => hits.stream);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    for (var i = 0; i < searchHitLimit; i++) {
      hits.add(_hit(1, 'a', 0, 1));
    }
    await hits.close();
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.text('Only the first $searchHitLimit matches are shown.'),
      findsOneWidget,
    );
  });

  testWidgets('back without a choice returns nothing', (tester) async {
    final results = await open(tester, (_) => const Stream.empty());

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
