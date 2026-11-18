import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/core/pdf/pdfrx_adapter.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  // Host tests have no Flutter plugins; use the pure-Dart initializer.
  setUpAll(() => pdfrxInitialize(tmpPath: Directory.systemTemp.path));

  group('PdfrxAdapter.inspect', () {
    test('reports the page count of a valid PDF', () async {
      final info = await PdfrxAdapter().inspect(
        'tests/fixtures/three_pages.pdf',
      );

      expect(info.pageCount, 3);
    });

    test('throws PdfOpenException for a file that is not a PDF', () async {
      await expectLater(
        PdfrxAdapter().inspect('tests/fixtures/not_a_pdf.pdf'),
        throwsA(isA<PdfOpenException>()),
      );
    });

    test('throws PdfOpenException for a missing file', () async {
      await expectLater(
        PdfrxAdapter().inspect('tests/fixtures/missing.pdf'),
        throwsA(isA<PdfOpenException>()),
      );
    });
  });
}
