import 'dart:isolate';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
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
  Widget pageView(
    String path, {
    int initialPage = 1,
    ValueChanged<int>? onPageChanged,
    List<PageHighlight> highlights = const [],
    List<SelectionAction> selectionActions = const [],
    ValueChanged<int>? onHighlightTap,
  }) => PdfViewer.file(
    path,
    initialPageNumber: initialPage,
    params: PdfViewerParams(
      onPageChanged: (page) {
        if (page != null) onPageChanged?.call(page);
      },
      pageOverlaysBuilder: (context, pageRect, page) {
        final scale = pageRect.width / page.width;
        return [
          for (final h in highlights.where((h) => h.page == page.pageNumber))
            for (final r in h.rects)
              Positioned(
                left: r.left * scale,
                top: r.top * scale,
                width: r.width * scale,
                height: r.height * scale,
                child: PdfOverlayInteractionRegion(
                  onTap: (_) {
                    onHighlightTap?.call(h.id);
                    return true;
                  },
                  child: ColoredBox(
                    color: Color(h.argb).withValues(alpha: 0.4),
                  ),
                ),
              ),
        ];
      },
      buildContextMenu: selectionActions.isEmpty
          ? null
          : (context, params) =>
                _SelectionMenu(actions: selectionActions, params: params),
    ),
  );

  @override
  Future<List<BBox>> textRects(
    String path, {
    required int page,
    required int start,
    required int end,
  }) async {
    final document = await _open(path);
    try {
      final pdfPage = document.pages[page - 1];
      final text = await pdfPage.loadStructuredText();
      final boxes = <BBox>[];
      for (var i = start; i < end && i < text.charRects.length; i++) {
        final r = text.charRects[i];
        if (r.width <= 0 || text.fullText[i].trim().isEmpty) continue;
        final box = BBox(
          r.left,
          pdfPage.height - r.top,
          r.right,
          pdfPage.height - r.bottom,
        );
        final last = boxes.isEmpty ? null : boxes.last;
        if (last != null &&
            (box.centerY - last.centerY).abs() < 0.5 * last.height &&
            box.left >= last.left) {
          boxes[boxes.length - 1] = last.union(box);
        } else {
          boxes.add(box);
        }
      }
      return boxes;
    } finally {
      await document.dispose();
    }
  }
}

/// Context menu with the app's selection actions.
class _SelectionMenu extends StatelessWidget {
  const new({required this.actions, required this.params});

  final List<SelectionAction> actions;
  final PdfViewerContextMenuBuilderParams params;

  Future<void> _run(SelectionAction action) async {
    final delegate = params.textSelectionDelegate;
    final ranges = await delegate.getSelectedTextRanges();
    params.dismissContextMenu();
    action.onSelected([
      for (final r in ranges)
        PdfSelection(
          page: r.pageNumber,
          start: r.start,
          end: r.end,
          text: r.text,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: params.anchorA.dx,
    top: params.anchorA.dy,
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in actions)
            TextButton(onPressed: () => _run(a), child: Text(a.label)),
        ],
      ),
    ),
  );
}
