import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/pdf/pdfrx_adapter.dart';

void main() {
  setUpAll(() => pdfrxInitialize(tmpPath: Directory.systemTemp.path));

  group('PdfrxAdapter.extractText graphics', () {
    const figures = 'tests/reflow_engine/corpus/two_column_figures.pdf';
    const plain = 'tests/reflow_engine/corpus/synthetic_single_column.pdf';

    test('pages with a caption carry their graphics, others none', () async {
      final input = await PdfrxAdapter().extractText(figures);

      expect(input.pages.where(pageNeedsGraphics), isNotEmpty);
      for (final page in input.pages) {
        expect(
          page.graphics != null,
          pageNeedsGraphics(page),
          reason: 'page ${page.number}',
        );
      }
    });

    test('the graphics of a figure page lie inside the page', () async {
      final input = await PdfrxAdapter().extractText(figures);
      final page = input.pages.firstWhere(pageNeedsGraphics);

      expect(page.graphics, isNotEmpty);
      for (final g in page.graphics!) {
        expect(g.left, inInclusiveRange(0, page.width));
        expect(g.right, inInclusiveRange(g.left, page.width));
        expect(g.top, inInclusiveRange(0, page.height));
        expect(g.bottom, inInclusiveRange(g.top, page.height));
      }
      // A figure is far larger than a glyph.
      expect(page.graphics!.any((g) => g.width > 50 && g.height > 50), isTrue);
    });

    test('a document of plain text is not analysed', () async {
      final input = await PdfrxAdapter().extractText(plain);

      expect(input.pages.map((p) => p.graphics), everyElement(isNull));
    });
  });
}
