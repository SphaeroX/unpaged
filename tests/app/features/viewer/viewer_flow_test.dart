import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paperflow/core/files/pdf_picker.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';

import '../../helpers/test_app.dart';

class _MockPicker extends Mock implements PdfPicker;

class _MockAdapter extends Mock implements PdfAdapter;

void main() {
  late _MockPicker picker;
  late _MockAdapter adapter;

  setUp(() {
    picker = _MockPicker();
    adapter = _MockAdapter();
    when(() => adapter.pageView(any()))
        .thenAnswer((inv) => Text('pages:${inv.positionalArguments.first}'));
  });

  List<dynamic> overrides() => [
    pdfPickerProvider.overrideWithValue(picker),
    pdfAdapterProvider.overrideWithValue(adapter),
  ];

  testWidgets('opens the picked PDF in the original page view', (tester) async {
    when(() => picker.pickPdf()).thenAnswer((_) async => '/docs/a.pdf');
    when(() => adapter.inspect('/docs/a.pdf'))
        .thenAnswer((_) async => const PdfInfo(pageCount: 3));

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await tester.tap(find.text('Open PDF'));
    await tester.pumpAndSettle();

    verify(() => adapter.inspect('/docs/a.pdf')).called(1);
    expect(find.text('pages:/docs/a.pdf'), findsOneWidget);
  });

  testWidgets('stays on the start screen when picking is cancelled', (
    tester,
  ) async {
    when(() => picker.pickPdf()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await tester.tap(find.text('Open PDF'));
    await tester.pumpAndSettle();

    verifyNever(() => adapter.inspect(any()));
    expect(find.text('Open PDF'), findsOneWidget);
  });

  testWidgets('shows a localized error for an unreadable PDF', (tester) async {
    when(() => picker.pickPdf()).thenAnswer((_) async => '/docs/broken.pdf');
    when(() => adapter.inspect('/docs/broken.pdf'))
        .thenThrow(const PdfOpenException('damaged'));

    await tester.pumpWidget(
      buildTestApp(overrides: overrides(), locale: const Locale('de')),
    );
    await tester.tap(find.text('PDF öffnen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Diese PDF konnte nicht geöffnet werden.'),
      findsOneWidget,
    );
    verifyNever(() => adapter.pageView(any()));
  });
}
