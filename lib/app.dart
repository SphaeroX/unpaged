import 'package:material_ui/material_ui.dart';
import 'package:paperflow/features/library/presentation/library_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

class PaperflowApp extends StatelessWidget {
  const new({super.key, this.locale});

  /// Forces a locale (tests); `null` follows the device language.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // material_ui's own delegates (Material, Cupertino, Widgets).
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LibraryScreen(),
    );
  }
}
