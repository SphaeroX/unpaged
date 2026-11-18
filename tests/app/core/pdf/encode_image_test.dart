import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unpaged/core/pdf/pdfrx_adapter.dart';

/// Behaves like PDFium's image: the pixel buffer is freed (here: wiped)
/// on dispose, so reading it afterwards returns garbage.
class _NativeLikeImage implements PdfImage {
  const new(this.pixels);

  @override
  final Uint8List pixels;

  @override
  int get width => 2;

  @override
  int get height => 1;

  @override
  void dispose() => pixels.fillRange(0, pixels.length, 0);
}

void main() {
  test('encodes the pixels before the native buffer is released', () async {
    // Blue then red pixel (BGRA).
    final image = _NativeLikeImage(
      Uint8List.fromList([255, 0, 0, 255, 0, 0, 255, 255]),
    );

    final png = await PdfrxAdapter.encodeAndDispose(image);

    expect(_rgbRows(png), [0, 0, 0, 255, 255, 0, 0]);
  });

  test('releases the image even if encoding fails', () async {
    final image = _NativeLikeImage(Uint8List(3)); // wrong size
    var disposed = false;
    final wrapped = _Spy(image, () => disposed = true);

    await expectLater(
      PdfrxAdapter.encodeAndDispose(wrapped),
      throwsA(anything),
    );
    expect(disposed, isTrue);
  });
}

class _Spy implements PdfImage {
  new(this._inner, this._onDispose);

  final PdfImage _inner;
  final void Function() _onDispose;

  @override
  Uint8List get pixels => _inner.pixels;

  @override
  int get width => _inner.width;

  @override
  int get height => _inner.height;

  @override
  void dispose() {
    _onDispose();
    _inner.dispose();
  }
}

List<int> _rgbRows(Uint8List png) {
  final data = ByteData.sublistView(png);
  var offset = 8;
  while (offset < png.length) {
    final length = data.getUint32(offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    if (type == 'IDAT') {
      return ZLibCodec().decode(png.sublist(offset + 8, offset + 8 + length));
    }
    offset += 12 + length;
  }
  throw StateError('no IDAT');
}
