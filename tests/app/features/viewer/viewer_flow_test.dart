import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unpaged/core/files/pdf_picker.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_env.dart';

class _MockPicker extends Mock implements PdfPicker;

class _MockAdapter extends Mock implements PdfAdapter;

// Since Task 05 "Open PDF" imports a copy into the library and opens that
// copy (approved change of the Task 01 flow, see Roadmap/README.md).
void main() {
  late _MockPicker picker;
  late _MockAdapter adapter;
  late TestEnv env;

  setUp(() {
    picker = _MockPicker();
    adapter = _MockAdapter();
    env = TestEnv();
    when(
      () => adapter.pageView(
        any(),
        controller: any(named: 'controller'),
        initialPage: any(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    ).thenAnswer((inv) => Text('pages:${inv.positionalArguments.first}'));
  });

  tearDown(() => env.dispose());

  List<dynamic> overrides() => [
    ...env.overrides,
    pdfPickerProvider.overrideWithValue(picker),
    pdfAdapterProvider.overrideWithValue(adapter),
  ];

  testWidgets('opens the picked PDF in the original page view', (tester) async {
    final bytes = fakePdf();
    final stored = env.store.fileFor(sha256.convert(bytes).toString()).path;
    when(() => picker.pickPdf())
        .thenAnswer((_) async => BytesPdfSource('a.pdf', bytes));
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 3));

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await tester.tap(find.text('Open PDF'));
    await settleIo(tester);

    verify(() => adapter.inspect(stored)).called(greaterThanOrEqualTo(1));
    expect(find.text('pages:$stored'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('stays on the start screen when picking is cancelled', (
    tester,
  ) async {
    when(() => picker.pickPdf()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestApp(overrides: overrides()));
    await tester.tap(find.text('Open PDF'));
    await settleIo(tester);

    verifyNever(() => adapter.inspect(any()));
    expect(find.text('Open PDF'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('shows a localized error for an unreadable PDF', (tester) async {
    when(() => picker.pickPdf())
        .thenAnswer((_) async => BytesPdfSource('broken.pdf', fakePdf()));
    when(() => adapter.inspect(any()))
        .thenThrow(const PdfOpenException('damaged'));

    await tester.pumpWidget(
      buildTestApp(overrides: overrides(), locale: const Locale('de')),
    );
    await tester.tap(find.text('PDF öffnen'));
    await settleIo(tester);

    expect(
      find.text('Diese PDF konnte nicht geöffnet werden.'),
      findsOneWidget,
    );
    verifyNever(
      () => adapter.pageView(
        any(),
        controller: any(named: 'controller'),
        initialPage: any(named: 'initialPage'),
        onPageChanged: any(named: 'onPageChanged'),
        highlights: any(named: 'highlights'),
        selectionActions: any(named: 'selectionActions'),
        onHighlightTap: any(named: 'onHighlightTap'),
      ),
    );

    await env.unmount(tester);
  });
}
