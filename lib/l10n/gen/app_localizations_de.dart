// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'paperflow';

  @override
  String get openPdf => 'PDF öffnen';

  @override
  String get pdfOpenError => 'Diese PDF konnte nicht geöffnet werden.';

  @override
  String get libraryEmpty =>
      'Noch keine Bücher. Öffne eine PDF, um zu beginnen.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0';
  }

  @override
  String get deleteBook => 'Löschen';

  @override
  String deleteConfirmTitle(String title) {
    return '„$title“ löschen?';
  }

  @override
  String get deleteConfirmBody =>
      'Die PDF-Kopie und alle zugehörigen Daten werden aus der App entfernt.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get alreadyInLibrary => 'Diese PDF ist bereits in deiner Bibliothek.';

  @override
  String reflowRunning(int percent) {
    return 'eBook wird vorbereitet … $percent %';
  }

  @override
  String get reflowFailed => 'eBook-Modus konnte nicht vorbereitet werden';

  @override
  String get reflowNoText => 'Kein Text – nur Originalansicht';
}
