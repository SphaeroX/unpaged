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

  @override
  String get readerUnavailable => 'The eBook version is missing or damaged.';

  @override
  String get prepareAgain => 'Prepare again';

  @override
  String get switchToEbook => 'eBook view';

  @override
  String get switchToOriginal => 'Original view';

  @override
  String get ebookNotReady => 'The eBook version is not ready yet.';

  @override
  String get zoomClose => 'Close';

  @override
  String get readingSettings => 'Reading settings';

  @override
  String get font => 'Font';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get fontSystem => 'System';

  @override
  String get textSize => 'Text size';

  @override
  String get largerText => 'Larger text';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get lineSpacing => 'Line spacing';

  @override
  String get widerLines => 'More line spacing';

  @override
  String get tighterLines => 'Less line spacing';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSepia => 'Sepia';

  @override
  String readProgress(int percent) {
    return '$percent % read';
  }

  @override
  String get highlight => 'Highlight';

  @override
  String get addNote => 'Add note';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get highlights => 'Highlights';

  @override
  String get noHighlights => 'No highlights yet.';

  @override
  String pageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get orphanedHighlight => 'Not found in the current version';
}
