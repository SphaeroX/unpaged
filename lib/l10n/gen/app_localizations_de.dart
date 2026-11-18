// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Unpaged';

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

  @override
  String get readerUnavailable =>
      'Die eBook-Fassung fehlt oder ist beschädigt.';

  @override
  String get prepareAgain => 'Neu vorbereiten';

  @override
  String get switchToEbook => 'eBook-Ansicht';

  @override
  String get switchToOriginal => 'Originalansicht';

  @override
  String get ebookNotReady => 'Die eBook-Fassung ist noch nicht fertig.';

  @override
  String get zoomClose => 'Schließen';

  @override
  String get readingSettings => 'Lese-Einstellungen';

  @override
  String get font => 'Schrift';

  @override
  String get fontSerif => 'Serifen';

  @override
  String get fontSans => 'Serifenlos';

  @override
  String get fontSystem => 'System';

  @override
  String get textSize => 'Schriftgröße';

  @override
  String get largerText => 'Größere Schrift';

  @override
  String get smallerText => 'Kleinere Schrift';

  @override
  String get lineSpacing => 'Zeilenabstand';

  @override
  String get widerLines => 'Mehr Zeilenabstand';

  @override
  String get tighterLines => 'Weniger Zeilenabstand';

  @override
  String get theme => 'Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSepia => 'Sepia';

  @override
  String readProgress(int percent) {
    return '$percent % gelesen';
  }

  @override
  String get highlight => 'Markieren';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get note => 'Notiz';

  @override
  String get save => 'Speichern';

  @override
  String get highlights => 'Markierungen';

  @override
  String get noHighlights => 'Noch keine Markierungen.';

  @override
  String pageLabel(int page) {
    return 'Seite $page';
  }

  @override
  String get orphanedHighlight => 'In der aktuellen Fassung nicht gefunden';
}
