import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/core/pdf/png_encoder.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// [PdfAdapter] backed by pdfrx (PDFium).
class PdfrxAdapter implements PdfAdapter {
  Future<PdfDocument> _open(String path) async {
    try {
      return await PdfDocument.openFile(path);
    } on Object catch (e) {
      throw PdfOpenException(e.toString());
    }
  }

  @override
  Future<PdfInfo> inspect(String path) async {
    final document = await _open(path);
    try {
      return PdfInfo(pageCount: document.pages.length);
    } finally {
      await document.dispose();
    }
  }

  @override
  Future<DocumentInput> extractText(String path) async {
    final document = await _open(path);
    try {
      return DocumentInput(
        pages: [for (final page in document.pages) await _extractPage(page)],
      );
    } finally {
      await document.dispose();
    }
  }

  static Future<PageInput> _extractPage(PdfPage page) async {
    final raw = await page.loadText();
    final chars = <TextChar>[];
    if (raw != null) {
      var wordStart = true;
      for (var i = 0; i < raw.fullText.length; i++) {
        final text = raw.fullText[i];
        if (text.trim().isEmpty && text != '\u0002') {
          // PDFium's generated spaces and line breaks separate words.
          wordStart = true;
          continue;
        }
        final r = raw.charRects[i];
        chars.add(
          TextChar(
            text: normalizeGlyph(text),
            box: BBox(
              _clamp(r.left, page.width),
              _clamp(page.height - r.top, page.height),
              _clamp(r.right, page.width),
              _clamp(page.height - r.bottom, page.height),
            ),
            wordStart: wordStart,
          ),
        );
        wordStart = false;
      }
    }
    return PageInput(
      number: page.pageNumber,
      width: page.width,
      height: page.height,
      chars: chars,
    );
  }

  @override
  Future<List<Uint8List>> renderRegions(
    String path,
    List<RegionRequest> regions, {
    double scale = 3,
  }) async {
    final document = await _open(path);
    try {
      final pngs = <Uint8List>[];
      for (final r in regions) {
        final page = document.pages[r.page - 1];
        final width = (r.box.width * scale).round().clamp(1, 1 << 14);
        final height = (r.box.height * scale).round().clamp(1, 1 << 14);
        final image = await page.render(
          x: (r.box.left * scale).round(),
          y: (r.box.top * scale).round(),
          width: width,
          height: height,
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (image == null) throw PdfOpenException('page ${r.page} not loaded');
        final pixels = image.pixels;
        final (w, h) = (image.width, image.height);
        image.dispose();
        pngs.add(
          await Isolate.run(
            () => encodePngFromBgra(pixels, width: w, height: h),
          ),
        );
      }
      return pngs;
    } finally {
      await document.dispose();
    }
  }

  /// Maps PDFium-specific code points to plain text.
  ///
  /// PDFium reports a hyphen it recognized at a line end as U+0002.
  static String normalizeGlyph(String glyph) => glyph == '\u0002' ? '-' : glyph;

  static double _clamp(double v, double max) => v.clamp(0, max).toDouble();

  @override
  Widget pageView(String path) => PdfViewer.file(path);
}
