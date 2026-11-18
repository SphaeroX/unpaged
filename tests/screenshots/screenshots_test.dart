import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/core/files/pdf_picker.dart';
import 'package:unpaged/core/files/pdf_source.dart';
import 'package:unpaged/features/reflow/data/reflow_store.dart';

import '../app/helpers/test_app.dart';
import 'sample_pdfs.g.dart';

/// Hands out the prepared files one after another, like a user picking them.
class _QueuePicker implements PdfPicker {
  new(this.paths);

  final List<String> paths;

  @override
  Future<PdfSource?> pickPdf() async =>
      paths.isEmpty ? null : FilePdfSource(paths.removeAt(0));
}

/// Waits in real time until [finder] matches nothing (or [timeout] passes).
Future<void> _waitUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(minutes: 3),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Still visible after $timeout: $finder');
}

/// Lets real time pass so PDF pages and images finish rendering.
Future<void> _settle(WidgetTester tester, [int seconds = 3]) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Captures the README screenshots (docs/screenshots/). Runs only through
/// `flutter drive` with tests/screenshots/driver.dart, which writes the PNGs;
/// see .github/workflows/screenshots.yml.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures the README screenshots', (tester) async {
    WidgetsApp.debugAllowBannerOverride = false; // no DEBUG ribbon
    await pdfrxFlutterInitialize();

    final tmp = Directory.systemTemp.createTempSync('unpaged_screenshots');
    Future<String> write(String name, String base64) async {
      final file = File('${tmp.path}/$name.pdf');
      await file.writeAsBytes(base64Decode(base64));
      return file.path;
    }

    // The title in the library comes from the file name.
    final paths = [
      await write('Reading on small screens', singleColumnPdf),
      await write('Typesetting in two columns', twoColumnPdf),
      await write('Electric fields in AlGaN photodiodes', paperPdf),
    ];

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          // Fresh library on every run (the app's own database survives
          // reinstalls of the test build).
          databaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
          pdfPickerProvider.overrideWithValue(_QueuePicker(paths)),
          bookFileStoreProvider.overrideWithValue(BookFileStore(tmp)),
          reflowStoreProvider.overrideWithValue(ReflowStore(tmp)),
        ],
      ),
    );
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // Import all three; each import opens the book, go back to the library.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Open PDF'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    await _waitUntilGone(tester, find.textContaining('Preparing eBook'));
    await _settle(tester, 1);
    await binding.takeScreenshot('01_library');

    // Original view of the two-column paper.
    await tester.tap(find.text('Electric fields in AlGaN photodiodes'));
    await tester.pumpAndSettle();
    await _settle(tester);
    await binding.takeScreenshot('02_original');

    // The same paper reflowed as an eBook.
    await tester.tap(find.byTooltip('eBook view'));
    await tester.pumpAndSettle();
    await _settle(tester);
    await binding.takeScreenshot('03_ebook');

    // The first region (table, figure or formula) kept as a crop of the page.
    // (`scrollUntilVisible` cannot take `.first` of a finder that is still
    // empty, so scroll by hand until the first crop is built.)
    final figure = find.byType(Image);
    for (var i = 0; i < 200 && figure.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(figure.first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 250));
    await tester.pumpAndSettle();
    await _settle(tester, 2);
    await binding.takeScreenshot('04_ebook_figure');

    // Reading settings with the sepia theme.
    await tester.tap(find.byTooltip('Reading settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sepia'));
    await tester.pumpAndSettle();
    await _settle(tester, 1);
    await binding.takeScreenshot('05_settings_sepia');

    // Dark theme, sheet closed.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 120)); // outside the sheet
    await tester.pumpAndSettle();
    await _settle(tester, 1);
    await binding.takeScreenshot('06_ebook_dark');
  });
}
