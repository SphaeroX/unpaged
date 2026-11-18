import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/theme/app_theme.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';

void main() {
  test('light, dark and sepia differ in brightness and background', () {
    final light = appTheme(ReaderTheme.light);
    final dark = appTheme(ReaderTheme.dark);
    final sepia = appTheme(ReaderTheme.sepia);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(sepia.brightness, Brightness.light);
    expect(sepia.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    expect(sepia.scaffoldBackgroundColor, sepiaBackground);
  });
}
