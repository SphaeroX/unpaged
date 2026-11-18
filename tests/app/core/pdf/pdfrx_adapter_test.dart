import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/core/pdf/pdfrx_adapter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';

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

  group('PdfrxAdapter.normalizeGlyph', () {
    test("maps PDFium's line-end hyphen marker U+0002 to '-'", () {
      expect(PdfrxAdapter.normalizeGlyph('\u0002'), '-');
    });

    test('keeps ordinary glyphs', () {
      expect(PdfrxAdapter.normalizeGlyph('a'), 'a');
    });
  });

  group('PdfrxAdapter.extractText', () {
    const synthetic = 'tests/reflow_engine/corpus/synthetic_single_column.pdf';

    test('returns one input page per PDF page with its size', () async {
      final input = await PdfrxAdapter().extractText(synthetic);

      expect(input.pages.map((p) => p.number), [1, 2]);
      expect(input.pages.first.width, closeTo(595.28, 0.01));
      expect(input.pages.first.height, closeTo(841.89, 0.01));
    });

    test('keeps visible glyphs only, with boxes inside the page', () async {
      final page = (await PdfrxAdapter().extractText(synthetic)).pages.first;

      expect(page.chars, isNotEmpty);
      expect(page.chars.where((c) => c.text.trim().isEmpty), isEmpty);
      for (final c in page.chars) {
        expect(c.box.left, inInclusiveRange(0, page.width));
        expect(c.box.right, inInclusiveRange(0, page.width));
        expect(c.box.top, inInclusiveRange(0, page.height));
        expect(c.box.bottom, greaterThanOrEqualTo(c.box.top));
      }
    });

    test('uses top-down coordinates and marks word starts', () async {
      final page = (await PdfrxAdapter().extractText(synthetic)).pages.first;
      final text = page.chars.map((c) => c.text).join();

      // The first glyph ("R" of "Reading") sits in the top margin area.
      expect(text, startsWith('Readinglong'));
      expect(page.chars.first.box.top, lessThan(100));
      expect(page.chars.first.wordStart, isTrue);
      expect(page.chars[1].wordStart, isFalse); // "e"
      expect(page.chars[7].wordStart, isTrue); // "l" of "long"
    });

    test('throws PdfOpenException for a broken file', () async {
      await expectLater(
        PdfrxAdapter().extractText('tests/fixtures/not_a_pdf.pdf'),
        throwsA(isA<PdfOpenException>()),
      );
    });
  });

  group('PdfrxAdapter.renderRegions', () {
    const pdf = 'tests/reflow_engine/corpus/synthetic_single_column.pdf';

    test('returns one PNG per requested region', () async {
      final pngs = await PdfrxAdapter().renderRegions(pdf, const [
        RegionRequest(page: 1, box: BBox(70, 70, 300, 120)),
        RegionRequest(page: 2, box: BBox(70, 70, 200, 100)),
      ]);

      expect(pngs, hasLength(2));
      for (final png in pngs) {
        expect(png.sublist(0, 4), [137, 80, 78, 71]);
      }
    });

    test('renders at the requested scale', () async {
      final png = (await PdfrxAdapter().renderRegions(pdf, const [
        RegionRequest(page: 1, box: BBox(0, 0, 100, 50)),
      ], scale: 2)).single;
      final header = ByteData.sublistView(png, 16);

      expect(header.getUint32(0), 200);
      expect(header.getUint32(4), 100);
    });
  });
}
