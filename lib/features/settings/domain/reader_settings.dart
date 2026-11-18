import 'package:flutter/foundation.dart';

/// Fonts bundled with the app (SIL OFL 1.1, see assets/fonts/).
enum ReaderFont {
  literata('Literata'),
  atkinson('AtkinsonHyperlegible'),
  system(null);

  new(this.family);

  /// Font family as registered in pubspec.yaml; `null` = platform default.
  final String? family;
}

enum ReaderTheme { light, dark, sepia }

/// How the eBook text is shown. Immutable; changes return a copy.
@immutable
class ReaderSettings {
  const new({
    required this.font,
    required this.fontSize,
    required this.lineHeight,
    required this.theme,
  });

  /// Unknown or broken values fall back to [defaults].
  factory fromMap(Map<String, String> map) {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return defaults.copyWith(
      font: byName(ReaderFont.values, map['font'], defaults.font),
      fontSize: double.tryParse(map['fontSize'] ?? ''),
      lineHeight: double.tryParse(map['lineHeight'] ?? ''),
      theme: byName(ReaderTheme.values, map['theme'], defaults.theme),
    );
  }

  static const defaults = ReaderSettings(
    font: ReaderFont.literata,
    fontSize: 18,
    lineHeight: 1.5,
    theme: ReaderTheme.light,
  );

  static const double minFontSize = 14;
  static const double maxFontSize = 30;
  static const double fontStep = 2;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2;
  static const double lineStep = 0.1;

  final ReaderFont font;
  final double fontSize;
  final double lineHeight;
  final ReaderTheme theme;

  ReaderSettings copyWith({
    ReaderFont? font,
    double? fontSize,
    double? lineHeight,
    ReaderTheme? theme,
  }) => ReaderSettings(
    font: font ?? this.font,
    fontSize: (fontSize ?? this.fontSize).clamp(minFontSize, maxFontSize),
    lineHeight: _round(
      (lineHeight ?? this.lineHeight).clamp(minLineHeight, maxLineHeight),
    ),
    theme: theme ?? this.theme,
  );

  ReaderSettings biggerFont() => copyWith(fontSize: fontSize + fontStep);
  ReaderSettings smallerFont() => copyWith(fontSize: fontSize - fontStep);
  ReaderSettings widerLines() => copyWith(lineHeight: lineHeight + lineStep);
  ReaderSettings tighterLines() => copyWith(lineHeight: lineHeight - lineStep);

  Map<String, String> toMap() => {
    'font': font.name,
    'fontSize': '$fontSize',
    'lineHeight': '$lineHeight',
    'theme': theme.name,
  };

  static double _round(double v) => (v * 10).roundToDouble() / 10;

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.font == font &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.theme == theme;

  @override
  int get hashCode => Object.hash(font, fontSize, lineHeight, theme);
}
