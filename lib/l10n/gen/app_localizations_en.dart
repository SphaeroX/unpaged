// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'paperflow';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get pdfOpenError => 'This PDF could not be opened.';

  @override
  String get libraryEmpty => 'No books yet. Open a PDF to start.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get deleteBook => 'Delete';

  @override
  String deleteConfirmTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get deleteConfirmBody =>
      'The PDF copy and all its data are removed from the app.';

  @override
  String get cancel => 'Cancel';

  @override
  String get alreadyInLibrary => 'This PDF is already in your library.';

  @override
  String reflowRunning(int percent) {
    return 'Preparing eBook … $percent %';
  }

  @override
  String get reflowFailed => 'eBook mode could not be prepared';

  @override
  String get reflowNoText => 'No text – original view only';
}
