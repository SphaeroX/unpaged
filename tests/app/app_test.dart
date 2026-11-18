import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/app.dart';

void main() {
  group('PaperflowApp', () {
    testWidgets('shows the open button in English', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: PaperflowApp(locale: Locale('en'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open PDF'), findsOneWidget);
    });

    testWidgets('shows the open button in German', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: PaperflowApp(locale: Locale('de'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF öffnen'), findsOneWidget);
    });
  });
}
