import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/pdf/graphics_detector.dart';

/// A white page of [width] × [height] pixels to draw on.
class _Canvas {
  new(this.width, this.height)
    : bgra = Uint8List(width * height * 4)
        ..fillRange(0, width * height * 4, 255);

  final int width;
  final int height;
  final Uint8List bgra;

  void fill(int left, int top, int right, int bottom, {int gray = 0}) {
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final i = (y * width + x) * 4;
        bgra[i] = gray;
        bgra[i + 1] = gray;
        bgra[i + 2] = gray;
      }
    }
  }

  List<BBox> detect({double scale = 1, List<BBox> text = const []}) =>
      detectGraphics(
        bgra,
        width: width,
        height: height,
        scale: scale,
        text: text,
      );
}

Matcher _near(BBox expected, {double slack = 3}) => predicate<BBox>(
  (b) =>
      (b.left - expected.left).abs() <= slack &&
      (b.top - expected.top).abs() <= slack &&
      (b.right - expected.right).abs() <= slack &&
      (b.bottom - expected.bottom).abs() <= slack,
  'within $slack pt of $expected',
);

void main() {
  test('a blank page has no graphics', () {
    expect(_Canvas(300, 400).detect(), isEmpty);
  });

  test('a picture yields its box in page points', () {
    final canvas = _Canvas(300, 400)..fill(100, 50, 200, 150, gray: 120);

    expect(canvas.detect(), [_near(const BBox(100, 50, 200, 150))]);
  });

  test('the box never cuts into the picture', () {
    final canvas = _Canvas(300, 400)..fill(101, 52, 199, 149);

    final box = canvas.detect().single;
    expect(box.left, lessThanOrEqualTo(101));
    expect(box.top, lessThanOrEqualTo(52));
    expect(box.right, greaterThanOrEqualTo(199));
    expect(box.bottom, greaterThanOrEqualTo(149));
  });

  test('pixels are converted with the render scale', () {
    final canvas = _Canvas(600, 800)..fill(200, 100, 400, 300);

    expect(canvas.detect(scale: 2), [_near(const BBox(100, 50, 200, 150))]);
  });

  test('glyphs of the text layer are no graphics', () {
    final canvas = _Canvas(300, 400)
      ..fill(50, 100, 56, 108)
      ..fill(58, 100, 64, 108);

    expect(
      canvas.detect(
        text: const [BBox(50, 100, 56, 108), BBox(58, 100, 64, 108)],
      ),
      isEmpty,
    );
  });

  test('a picture keeps its box when labels are printed inside it', () {
    final canvas = _Canvas(300, 400)..fill(100, 50, 200, 150, gray: 200);

    expect(canvas.detect(text: const [BBox(140, 90, 150, 98)]), [
      _near(const BBox(100, 50, 200, 150)),
    ]);
  });

  test('pictures far apart are separate, nearby parts are one', () {
    final canvas = _Canvas(300, 400)
      ..fill(20, 20, 120, 100)
      ..fill(124, 20, 200, 100) // 4 pt beside the first: same drawing
      ..fill(20, 250, 120, 330);

    final boxes = canvas.detect()..sort((a, b) => a.top.compareTo(b.top));

    expect(boxes, [
      _near(const BBox(20, 20, 200, 100)),
      _near(const BBox(20, 250, 120, 330)),
    ]);
  });

  test('specks are dropped, thin rules are kept', () {
    final canvas = _Canvas(300, 400)
      ..fill(30, 30, 32, 32)
      ..fill(40, 200, 260, 201);

    expect(canvas.detect(), [_near(const BBox(40, 200, 260, 201))]);
  });

  test('almost white pixels (paper, compression noise) are no ink', () {
    final canvas = _Canvas(300, 400)..fill(100, 50, 200, 150, gray: 246);

    expect(canvas.detect(), isEmpty);
  });

  test('rejects a pixel buffer of the wrong size', () {
    expect(
      () => detectGraphics(
        Uint8List(10),
        width: 3,
        height: 3,
        scale: 1,
        text: const [],
      ),
      throwsArgumentError,
    );
  });
}
