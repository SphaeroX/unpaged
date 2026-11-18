import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';
import 'helpers/test_env.dart';

// Since Task 05 the app needs storage; the tests run it on a test database
// (approved adaptation, see Roadmap/README.md).
void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  group('PaperflowApp', () {
    testWidgets('shows the open button in English', (tester) async {
      await tester.pumpWidget(buildTestApp(overrides: env.overrides));
      await settleIo(tester);

      expect(find.text('Open PDF'), findsOneWidget);
      await env.unmount(tester);
    });

    testWidgets('shows the open button in German', (tester) async {
      await tester.pumpWidget(
        buildTestApp(overrides: env.overrides, locale: const Locale('de')),
      );
      await settleIo(tester);

      expect(find.text('PDF öffnen'), findsOneWidget);
      await env.unmount(tester);
    });
  });
}
