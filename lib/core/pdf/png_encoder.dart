import 'dart:io';
import 'dart:typed_data';

/// Encodes BGRA8888 pixels (as rendered by PDFium) as an RGB PNG.
///
/// Pure Dart, so it can run in a background isolate. Alpha is dropped:
/// pages are rendered on a white background.
Uint8List encodePngFromBgra(
  Uint8List bgra, {
  required int width,
  required int height,
}) {
  if (bgra.length != width * height * 4) {
    throw ArgumentError('expected ${width * height * 4} bytes');
  }
  final raw = Uint8List(height * (1 + width * 3));
  var o = 0;
  for (var y = 0; y < height; y++) {
    raw[o++] = 0; // filter: none
    var i = y * width * 4;
    for (var x = 0; x < width; x++, i += 4) {
      raw[o++] = bgra[i + 2];
      raw[o++] = bgra[i + 1];
      raw[o++] = bgra[i];
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // colour type RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final out = BytesBuilder(copy: false)
    ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', Uint8List.fromList(ZLibCodec().encode(raw))))
    ..add(_chunk('IEND', Uint8List(0)));
  return out.takeBytes();
}

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final chunk = ByteData(12 + data.length)..setUint32(0, data.length);
  final bytes = chunk.buffer.asUint8List()
    ..setRange(4, 8, typeBytes)
    ..setRange(8, 8 + data.length, data);
  chunk.setUint32(8 + data.length, _crc(bytes, 4, 8 + data.length));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc(Uint8List bytes, int start, int end) {
  var c = 0xFFFFFFFF;
  for (var i = start; i < end; i++) {
    c = _crcTable[(c ^ bytes[i]) & 0xFF] ^ (c >>> 8);
  }
  return c ^ 0xFFFFFFFF;
}
