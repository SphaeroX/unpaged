import 'dart:typed_data';

import 'package:reflow_engine/reflow_engine.dart';

/// Brightness below which a pixel counts as ink; paper and compression
/// noise in scanned pictures stay above it.
const _inkLevel = 232;

/// Edge of a grid cell in page points.
const _cellPoints = 3.0;

/// Cells this far apart still belong to one drawing (dashed lines, the
/// parts of a chart); pictures of different figures lie further apart.
const _reach = 2;

/// Graphics smaller than this in both directions are specks.
const _minExtent = 6.0;

/// Finds what a rendered page shows besides its text: pictures, drawings
/// and rules.
///
/// [bgra] holds the BGRA8888 pixels of the whole page, rendered on white at
/// [scale] pixels per point. Pixels covered by the glyph boxes in [text]
/// (page points, top-down) are ignored. Returns one box per connected
/// drawing, in page points. Pure Dart.
List<BBox> detectGraphics(
  Uint8List bgra, {
  required int width,
  required int height,
  required double scale,
  required Iterable<BBox> text,
}) {
  if (bgra.length != width * height * 4) {
    throw ArgumentError('expected ${width * height * 4} bytes');
  }

  // Glyphs, one pixel wider for their anti-aliased edges.
  final isText = Uint8List(width * height);
  for (final glyph in text) {
    final left = ((glyph.left * scale).floor() - 1).clamp(0, width);
    final top = ((glyph.top * scale).floor() - 1).clamp(0, height);
    final right = ((glyph.right * scale).ceil() + 1).clamp(0, width);
    final bottom = ((glyph.bottom * scale).ceil() + 1).clamp(0, height);
    for (var y = top; y < bottom; y++) {
      isText.fillRange(y * width + left, y * width + right, 1);
    }
  }

  // Ink per grid cell, with the exact pixel extent inside each cell.
  final cell = (_cellPoints * scale).round().clamp(1, 1 << 20);
  final columns = (width + cell - 1) ~/ cell;
  final rows = (height + cell - 1) ~/ cell;
  final ink = Uint16List(columns * rows);
  final minX = Int32List(columns * rows)..fillRange(0, columns * rows, width);
  final minY = Int32List(columns * rows)..fillRange(0, columns * rows, height);
  final maxX = Int32List(columns * rows)..fillRange(0, columns * rows, -1);
  final maxY = Int32List(columns * rows)..fillRange(0, columns * rows, -1);
  for (var y = 0; y < height; y++) {
    final row = (y ~/ cell) * columns;
    var i = y * width * 4;
    for (var x = 0; x < width; x++, i += 4) {
      if (bgra[i] >= _inkLevel &&
          bgra[i + 1] >= _inkLevel &&
          bgra[i + 2] >= _inkLevel) {
        continue;
      }
      if (isText[y * width + x] == 1) continue;
      final c = row + x ~/ cell;
      if (ink[c] < 0xffff) ink[c]++;
      if (x < minX[c]) minX[c] = x;
      if (x > maxX[c]) maxX[c] = x;
      if (y < minY[c]) minY[c] = y;
      if (y > maxY[c]) maxY[c] = y;
    }
  }

  // Connected cells form one drawing.
  final seen = Uint8List(columns * rows);
  final boxes = <BBox>[];
  final queue = <int>[];
  for (var start = 0; start < ink.length; start++) {
    if (ink[start] < 2 || seen[start] == 1) continue;
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    seen[start] = 1;
    queue
      ..clear()
      ..add(start);
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      if (minX[c] < left) left = minX[c];
      if (minY[c] < top) top = minY[c];
      if (maxX[c] > right) right = maxX[c];
      if (maxY[c] > bottom) bottom = maxY[c];
      final cx = c % columns;
      final cy = c ~/ columns;
      for (var dy = -_reach; dy <= _reach; dy++) {
        final ny = cy + dy;
        if (ny < 0 || ny >= rows) continue;
        for (var dx = -_reach; dx <= _reach; dx++) {
          final nx = cx + dx;
          if (nx < 0 || nx >= columns) continue;
          final n = ny * columns + nx;
          if (ink[n] < 2 || seen[n] == 1) continue;
          seen[n] = 1;
          queue.add(n);
        }
      }
    }
    final box = BBox(
      left / scale,
      top / scale,
      (right + 1) / scale,
      (bottom + 1) / scale,
    );
    if (box.width >= _minExtent || box.height >= _minExtent) boxes.add(box);
  }
  return boxes;
}
