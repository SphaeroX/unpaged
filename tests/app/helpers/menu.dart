import 'package:flutter_test/flutter_test.dart';

/// Opens the ⋮ menu of the app bar and taps [label]. Since the app bar was
/// tidied up, every screen action except the GitHub link lives there.
Future<void> chooseFromMenu(
  WidgetTester tester,
  String label, {
  String menuTooltip = 'More options',
}) async {
  await tester.tap(find.byTooltip(menuTooltip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
}
