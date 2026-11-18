import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/theme/app_theme.dart';
import 'package:unpaged/features/library/presentation/library_screen.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';
import 'package:unpaged/features/settings/presentation/reader_settings_controller.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

class UnpagedApp extends ConsumerWidget {
  const new({super.key, this.locale, this.home});

  /// Forces a locale (tests); `null` follows the device language.
  final Locale? locale;

  /// Start screen override (tests); defaults to the library.
  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(readerSettingsProvider).value ?? ReaderSettings.defaults;
    return MaterialApp(
      theme: appTheme(settings.theme),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // material_ui's own delegates (Material, Cupertino, Widgets).
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home ?? const LibraryScreen(),
    );
  }
}
