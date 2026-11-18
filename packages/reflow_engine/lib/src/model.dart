import 'package:meta/meta.dart';

double _r(double v) => (v * 100).roundToDouble() / 100;

/// Axis-aligned box in page points, origin top-left, y grows downwards.
@immutable
class BBox {
  const new(this.left, this.top, this.right, this.bottom);

  factory fromJson(List<dynamic> json) => BBox(
    (json[0] as num).toDouble(),
    (json[1] as num).toDouble(),
    (json[2] as num).toDouble(),
    (json[3] as num).toDouble(),
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;

  BBox union(BBox other) => BBox(
    left < other.left ? left : other.left,
    top < other.top ? top : other.top,
    right > other.right ? right : other.right,
    bottom > other.bottom ? bottom : other.bottom,
  );

  List<double> toJson() => [_r(left), _r(top), _r(right), _r(bottom)];

  @override
  bool operator ==(Object other) =>
      other is BBox &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'BBox($left, $top, $right, $bottom)';
}

/// One visible glyph of a page.
@immutable
class TextChar {
  const new({required this.text, required this.box, this.wordStart = false});

  factory fromJson(List<dynamic> json) => TextChar(
    text: json[0] as String,
    box: BBox.fromJson(json.sublist(1, 5)),
    wordStart: json[5] == 1,
  );

  /// The glyph's text, usually a single character.
  final String text;

  /// Tight glyph box (top-down coordinates).
  final BBox box;

  /// Whether the PDF marks this glyph as the first of a word.
  final bool wordStart;

  TextChar copyWith({bool? wordStart}) =>
      TextChar(text: text, box: box, wordStart: wordStart ?? this.wordStart);

  List<Object> toJson() => [text, ...box.toJson(), if (wordStart) 1 else 0];

  @override
  bool operator ==(Object other) =>
      other is TextChar &&
      other.text == text &&
      other.box == box &&
      other.wordStart == wordStart;

  @override
  int get hashCode => Object.hash(text, box, wordStart);
}

/// The characters of one page as delivered by the PDF adapter.
@immutable
class PageInput {
  const new({
    required this.number,
    required this.width,
    required this.height,
    required this.chars,
  });

  factory fromJson(Map<String, dynamic> json) => PageInput(
    number: json['n'] as int,
    width: (json['w'] as num).toDouble(),
    height: (json['h'] as num).toDouble(),
    chars: [
      for (final c in json['c'] as List<dynamic>)
        TextChar.fromJson(c as List<dynamic>),
    ],
  );

  /// 1-based page number.
  final int number;
  final double width;
  final double height;
  final List<TextChar> chars;

  Map<String, dynamic> toJson() => {
    'n': number,
    'w': _r(width),
    'h': _r(height),
    'c': [for (final c in chars) c.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is PageInput &&
      other.number == number &&
      other.width == width &&
      other.height == height &&
      _listEquals(other.chars, chars);

  @override
  int get hashCode => Object.hash(number, width, height, chars.length);
}

/// All pages of a document.
@immutable
class DocumentInput {
  const new({required this.pages});

  factory fromJson(Map<String, dynamic> json) => DocumentInput(
    pages: [
      for (final p in json['pages'] as List<dynamic>)
        PageInput.fromJson(p as Map<String, dynamic>),
    ],
  );

  final List<PageInput> pages;

  Map<String, dynamic> toJson() => {
    'pages': [for (final p in pages) p.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is DocumentInput && _listEquals(other.pages, pages);

  @override
  int get hashCode => pages.length.hashCode;
}

enum BlockType {
  heading,
  paragraph,
  listItem,
  caption,

  /// Non-text regions, shown as an image crop of the original page.
  table,
  figure,
  formula;

  bool get isRegion => this == table || this == figure || this == formula;
}

/// One reflowable unit of the document.
@immutable
class ReflowBlock {
  const new({
    required this.id,
    required this.type,
    required this.text,
    required this.page,
    required this.box,
    this.level,
  });

  factory fromJson(Map<String, dynamic> json) => ReflowBlock(
    id: json['id'] as String,
    type: BlockType.values.byName(json['type'] as String),
    text: json['text'] as String,
    page: json['page'] as int,
    box: BBox.fromJson(json['box'] as List<dynamic>),
    level: json['level'] as int?,
  );

  /// Stable id, unique within the document (e.g. `p3b12`).
  final String id;
  final BlockType type;
  final String text;

  /// 1-based page the block starts on.
  final int page;

  /// Area of the block on its page.
  final BBox box;

  /// Heading level (1 = most prominent); `null` for other block types.
  final int? level;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    if (level != null) 'level': level,
    'text': text,
    'page': page,
    'box': box.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is ReflowBlock &&
      other.id == id &&
      other.type == type &&
      other.text == text &&
      other.page == page &&
      other.box == box &&
      other.level == level;

  @override
  int get hashCode => Object.hash(id, type, text, page, box, level);

  @override
  String toString() => 'ReflowBlock($id, $type, "$text")';
}

/// Result of the reflow engine.
@immutable
class ReflowDocument {
  const new({required this.engineVersion, required this.blocks});

  factory fromJson(Map<String, dynamic> json) => ReflowDocument(
    engineVersion: json['engineVersion'] as int,
    blocks: [
      for (final b in json['blocks'] as List<dynamic>)
        ReflowBlock.fromJson(b as Map<String, dynamic>),
    ],
  );

  final int engineVersion;
  final List<ReflowBlock> blocks;

  Map<String, dynamic> toJson() => {
    'engineVersion': engineVersion,
    'blocks': [for (final b in blocks) b.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ReflowDocument &&
      other.engineVersion == engineVersion &&
      _listEquals(other.blocks, blocks);

  @override
  int get hashCode => Object.hash(engineVersion, blocks.length);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
