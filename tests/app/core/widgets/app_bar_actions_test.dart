import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unpaged/core/platform/external_link_channel.dart';
import 'package:unpaged/core/widgets/app_bar_actions.dart';

import '../../helpers/test_app.dart';

class _MockLinks extends Mock implements ExternalLinkChannel;

void main() {
  late _MockLinks links;

  setUp(() {
    links = _MockLinks();
    when(() => links.open(any())).thenAnswer((_) async => true);
  });

  Future<void> pump(
    WidgetTester tester, {
    List<MenuEntry> entries = const [],
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    buildTestApp(
      locale: locale,
      overrides: [externalLinkChannelProvider.overrideWithValue(links)],
      home: Scaffold(appBar: AppBar(actions: appBarActions(entries))),
    ),
  );

  testWidgets('the GitHub button opens the repository', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Unpaged on GitHub'));
    await tester.pumpAndSettle();

    verify(() => links.open('https://github.com/SphaeroX/unpaged')).called(1);
  });

  testWidgets('tells the user when no browser can open it', (tester) async {
    when(() => links.open(any())).thenAnswer((_) async => false);
    await pump(tester, locale: const Locale('de'));

    await tester.tap(find.byTooltip('Unpaged auf GitHub'));
    await tester.pumpAndSettle();

    expect(
      find.text('Keine App gefunden, die den Link öffnen kann.'),
      findsOneWidget,
    );
  });

  testWidgets('everything else sits in the ⋮ menu', (tester) async {
    final chosen = <String>[];
    await pump(
      tester,
      entries: [
        MenuEntry(
          icon: Icons.search,
          label: 'Search',
          onSelected: () => chosen.add('search'),
        ),
        MenuEntry(
          icon: Icons.print_outlined,
          label: 'Print',
          onSelected: () => chosen.add('print'),
        ),
      ],
    );

    expect(find.byType(IconButton), findsNWidgets(2)); // GitHub and ⋮.
    expect(find.text('Print'), findsNothing);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();

    expect(chosen, ['print']);
  });
}
