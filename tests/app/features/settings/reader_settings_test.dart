import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';

void main() {
  const defaults = ReaderSettings.defaults;

  test('has sensible defaults', () {
    expect(defaults.font, ReaderFont.literata);
    expect(defaults.fontSize, 18);
    expect(defaults.lineHeight, 1.5);
    expect(defaults.theme, ReaderTheme.light);
  });

  test('font size changes in steps and stays within its limits', () {
    expect(defaults.biggerFont().fontSize, 20);
    expect(defaults.smallerFont().fontSize, 16);
    var s = defaults;
    for (var i = 0; i < 20; i++) {
      s = s.biggerFont();
    }
    expect(s.fontSize, ReaderSettings.maxFontSize);
    for (var i = 0; i < 20; i++) {
      s = s.smallerFont();
    }
    expect(s.fontSize, ReaderSettings.minFontSize);
  });

  test('line height changes in steps and stays within its limits', () {
    expect(defaults.widerLines().lineHeight, closeTo(1.6, 1e-9));
    var s = defaults;
    for (var i = 0; i < 20; i++) {
      s = s.tighterLines();
    }
    expect(s.lineHeight, closeTo(ReaderSettings.minLineHeight, 1e-9));
  });

  test('round-trips through its storage map', () {
    final s = defaults
        .copyWith(font: ReaderFont.atkinson, theme: ReaderTheme.sepia)
        .biggerFont()
        .widerLines();

    expect(ReaderSettings.fromMap(s.toMap()), s);
  });

  test('unknown or broken stored values fall back to defaults', () {
    expect(
      ReaderSettings.fromMap(const {
        'font': 'comic',
        'fontSize': 'x',
        'theme': '?',
      }),
      defaults,
    );
  });
}
