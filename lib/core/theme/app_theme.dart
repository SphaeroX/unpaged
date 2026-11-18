import 'package:material_ui/material_ui.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';

const _seed = Color(0xFF3D5A80);

/// Warm paper background and brown text of the sepia theme.
const sepiaBackground = Color(0xFFF4ECD8);
const sepiaText = Color(0xFF5B4636);

ThemeData appTheme(ReaderTheme theme) => switch (theme) {
  ReaderTheme.light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  ),
  ReaderTheme.dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  ),
  ReaderTheme.sepia => _sepia(),
};

ThemeData _sepia() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF8B6B4A))
      .copyWith(surface: sepiaBackground, onSurface: sepiaText);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: sepiaBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: sepiaBackground,
      foregroundColor: sepiaText,
    ),
  );
}
