import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpaged'**
  String get appTitle;

  /// Button that opens the system file picker for a PDF
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// Shown when a PDF file is unreadable or damaged
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be opened.'**
  String get pdfOpenError;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No books yet. Open a PDF to start.'**
  String get libraryEmpty;

  /// No description provided for @pageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pageCount(int count);

  /// No description provided for @deleteBook.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBook;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String deleteConfirmTitle(String title);

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The PDF copy and all its data are removed from the app.'**
  String get deleteConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @alreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'This PDF is already in your library.'**
  String get alreadyInLibrary;

  /// No description provided for @reflowRunning.
  ///
  /// In en, this message translates to:
  /// **'Preparing eBook … {percent} %'**
  String reflowRunning(int percent);

  /// No description provided for @reflowFailed.
  ///
  /// In en, this message translates to:
  /// **'eBook mode could not be prepared'**
  String get reflowFailed;

  /// No description provided for @reflowNoText.
  ///
  /// In en, this message translates to:
  /// **'No text – original view only'**
  String get reflowNoText;

  /// No description provided for @readerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The eBook version is missing or damaged.'**
  String get readerUnavailable;

  /// No description provided for @prepareAgain.
  ///
  /// In en, this message translates to:
  /// **'Prepare again'**
  String get prepareAgain;

  /// No description provided for @switchToEbook.
  ///
  /// In en, this message translates to:
  /// **'eBook view'**
  String get switchToEbook;

  /// No description provided for @switchToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original view'**
  String get switchToOriginal;

  /// No description provided for @ebookNotReady.
  ///
  /// In en, this message translates to:
  /// **'The eBook version is not ready yet.'**
  String get ebookNotReady;

  /// No description provided for @zoomClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get zoomClose;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readingSettings;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @fontSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// No description provided for @fontSans.
  ///
  /// In en, this message translates to:
  /// **'Sans'**
  String get fontSans;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get fontSystem;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @largerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get largerText;

  /// No description provided for @smallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get smallerText;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineSpacing;

  /// No description provided for @widerLines.
  ///
  /// In en, this message translates to:
  /// **'More line spacing'**
  String get widerLines;

  /// No description provided for @tighterLines.
  ///
  /// In en, this message translates to:
  /// **'Less line spacing'**
  String get tighterLines;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @readProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent} % read'**
  String readProgress(int percent);

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @noHighlights.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet.'**
  String get noHighlights;

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageLabel(int page);

  /// No description provided for @orphanedHighlight.
  ///
  /// In en, this message translates to:
  /// **'Not found in the current version'**
  String get orphanedHighlight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
