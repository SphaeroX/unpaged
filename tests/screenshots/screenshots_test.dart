import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart' show BackButton;
import 'package:pdfrx/pdfrx.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/core/files/pdf_picker.dart';
import 'package:unpaged/core/files/pdf_source.dart';
import 'package:unpaged/features/reflow/data/reflow_store.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

import '../app/helpers/menu.dart';
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

/// Waits in real time until [finder] matches something (or [timeout] passes).
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(minutes: 1),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Not visible after $timeout: $finder');
}

/// Lets real time pass so PDF pages and images finish rendering.
Future<void> _settle(WidgetTester tester, [int seconds = 3]) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// UI language of the run: `--dart-define=SCREENSHOT_LOCALE=de` captures the
/// German screenshots into docs/screenshots/de/ (for the Play Store);
/// the default `en` writes the README screenshots to docs/screenshots/.
const _localeName = String.fromEnvironment(
  'SCREENSHOT_LOCALE',
  defaultValue: 'en',
);

/// Captures the README and Play Store screenshots (docs/screenshots/). Runs
/// only through `flutter drive` with tests/screenshots/driver.dart, which
/// writes the PNGs; see .github/workflows/screenshots.yml.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const locale = Locale(_localeName);
  final l10n = lookupAppLocalizations(locale);
  const prefix = _localeName == 'en' ? '' : '$_localeName/';
  const german = _localeName == 'de';

  testWidgets('captures the screenshots', (tester) async {
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
      await write(
        german ? 'Lesen auf kleinen Bildschirmen' : 'Reading on small screens',
        singleColumnPdf,
      ),
      await write(
        german ? 'Satz in zwei Spalten' : 'Typesetting in two columns',
        twoColumnPdf,
      ),
      await write('Electric fields in AlGaN photodiodes', paperPdf),
    ];

    await tester.pumpWidget(
      buildTestApp(
        // Not redundant: SCREENSHOT_LOCALE changes it at build time.
        // ignore: avoid_redundant_argument_values
        locale: locale,
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
      await tester.tap(find.text(l10n.openPdf));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Opening the book can take longer on a cold emulator. Tap the
      // BackButton itself: `pageBack()` looks for the English tooltip "Back".
      await _waitFor(tester, find.byType(BackButton));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    await _waitUntilGone(
      tester,
      find.textContaining(l10n.reflowRunning(0).split('…').first.trim()),
    );
    await _settle(tester, 1);
    await binding.takeScreenshot('${prefix}01_library');

    // Original view of the two-column paper.
    await tester.tap(find.text('Electric fields in AlGaN photodiodes'));
    await tester.pumpAndSettle();
    await _settle(tester);
    await binding.takeScreenshot('${prefix}02_original');

    // The same paper reflowed as an eBook.
    await chooseFromMenu(
      tester,
      l10n.switchToEbook,
      menuTooltip: l10n.moreOptions,
    );
    await tester.pumpAndSettle();
    await _settle(tester);
    await binding.takeScreenshot('${prefix}03_ebook');

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
    await binding.takeScreenshot('${prefix}04_ebook_figure');

    // Reading settings with the sepia theme.
    await chooseFromMenu(
      tester,
      l10n.readingSettings,
      menuTooltip: l10n.moreOptions,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.themeSepia));
    await tester.pumpAndSettle();
    await _settle(tester, 1);
    await binding.takeScreenshot('${prefix}05_settings_sepia');

    // Dark theme, sheet closed.
    await tester.tap(find.text(l10n.themeDark));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 120)); // outside the sheet
    await tester.pumpAndSettle();
    await _settle(tester, 1);
    await binding.takeScreenshot('${prefix}06_ebook_dark');
  });
}
