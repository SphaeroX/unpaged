import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/pdf/png_encoder.dart';

void main() {
  // 2×1 image: blue pixel, then red pixel (BGRA input).
  final bgra = Uint8List.fromList([255, 0, 0, 255, 0, 0, 255, 255]);

  test('starts with the PNG signature and an IHDR of the right size', () {
    final png = encodePngFromBgra(bgra, width: 2, height: 1);

    expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData.sublistView(png, 8);
    expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
    expect(header.getUint32(8), 2); // width
    expect(header.getUint32(12), 1); // height
    expect(png[24], 8); // bit depth
    expect(png[25], 2); // colour type RGB
  });

  test('stores the pixels as RGB rows with filter byte 0', () {
    final png = encodePngFromBgra(bgra, width: 2, height: 1);
    final idat = _chunk(png, 'IDAT');

    expect(ZLibCodec().decode(idat), [0, 0, 0, 255, 255, 0, 0]);
  });

  test('ends with an IEND chunk', () {
    final png = encodePngFromBgra(bgra, width: 2, height: 1);

    expect(
      String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
      'IEND',
    );
  });

  test('rejects pixel data of the wrong size', () {
    expect(
      () => encodePngFromBgra(Uint8List(3), width: 2, height: 1),
      throwsArgumentError,
    );
  });
}

List<int> _chunk(Uint8List png, String type) {
  var offset = 8;
  final data = ByteData.sublistView(png);
  while (offset < png.length) {
    final length = data.getUint32(offset);
    final name = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    if (name == type) return png.sublist(offset + 8, offset + 8 + length);
    offset += 12 + length;
  }
  throw StateError('no $type');
}
