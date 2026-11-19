import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/core/pdf/png_encoder.dart';

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
        final longest = r.box.width > r.box.height ? r.box.width : r.box.height;
        final s = longest * scale > maxCropSide ? maxCropSide / longest : scale;
        final image = await page.render(
          x: (r.box.left * s).round(),
          y: (r.box.top * s).round(),
          width: (r.box.width * s).round().clamp(1, maxCropSide),
          height: (r.box.height * s).round().clamp(1, maxCropSide),
          fullWidth: page.width * s,
          fullHeight: page.height * s,
        );
        if (image == null) throw PdfOpenException('page ${r.page} not loaded');
        pngs.add(await encodeAndDispose(image));
      }
      return pngs;
    } finally {
      await document.dispose();
    }
  }

  /// Longest side of a rendered crop in pixels (keeps memory bounded on
  /// phones; ~3,000 px is still sharp when zoomed).
  static const maxCropSide = 3000;

  /// Encodes [image] as PNG and releases it.
  ///
  /// PDFium's pixel buffer is native memory that `dispose` frees, so the
  /// pixels are copied into Dart memory first; reading them afterwards
  /// crashed the app on Android.
  static Future<Uint8List> encodeAndDispose(PdfImage image) async {
    final Uint8List pixels;
    final int w;
    final int h;
    try {
      pixels = Uint8List.fromList(image.pixels);
      (w, h) = (image.width, image.height);
    } finally {
      image.dispose();
    }
    return await Isolate.run(
      () => encodePngFromBgra(pixels, width: w, height: h),
    );
  }

  /// Maps PDFium-specific code points to plain text.
  ///
  /// PDFium reports a hyphen it recognized at a line end as U+0002.
  static String normalizeGlyph(String glyph) => glyph == '\u0002' ? '-' : glyph;

  static double _clamp(double v, double max) => v.clamp(0, max).toDouble();

  /// pdfrx keeps the controller it saw first, so each screen's
  /// [PageViewController] maps to one pdfrx controller for its lifetime.
  final _viewers = Expando<PdfViewerController>();

  PdfViewerController? _viewerFor(PageViewController? controller) {
    if (controller == null) return null;
    final viewer = _viewers[controller] ??= PdfViewerController();
    controller.goToHandler = (page) async {
      if (viewer.isReady) await viewer.goToPage(pageNumber: page);
    };
    return viewer;
  }

  @override
  Widget pageView(
    String path, {
    PageViewController? controller,
    int initialPage = 1,
    ValueChanged<int>? onPageChanged,
    List<PageHighlight> highlights = const [],
    List<SelectionAction> selectionActions = const [],
    ValueChanged<int>? onHighlightTap,
  }) {
    final viewer = _viewerFor(controller);
    return PdfViewer.file(
      path,
      controller: viewer,
      initialPageNumber: initialPage,
      params: PdfViewerParams(
        viewerOverlayBuilder: viewer == null
            ? null
            : (context, size, _) => [
                PdfViewerScrollThumb(
                  controller: viewer,
                  thumbSize: const Size(48, 36),
                  thumbBuilder: (context, size, page, _) =>
                      _thumb(context, page),
                ),
              ],
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
        // Extend pdfrx' own menu (Copy, Select all); a replaced menu has to
        // position itself, and a wrongly nested Positioned shows a grey box.
        customizeContextMenuItems: (params, items) {
          final delegate = params.textSelectionDelegate;
          addSelectionActions(
            items,
            selectionActions,
            hasSelection:
                params.isTextSelectionEnabled && delegate.hasSelectedText,
            selection: () async => [
              for (final r in await delegate.getSelectedTextRanges())
                PdfSelection(
                  page: r.pageNumber,
                  start: r.start,
                  end: r.end,
                  text: r.text,
                ),
            ],
            dismiss: () => unawaited(delegate.clearTextSelection()),
          );
        },
      ),
    );
  }

  /// The grip of the fast-scroll thumb with the current page number.
  static Widget _thumb(BuildContext context, int? page) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      elevation: 2,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
      child: Center(
        child: Text(
          page == null ? '' : '$page',
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }

  /// Puts [actions] in front of the default selection [items], so Android
  /// does not hide them in the overflow menu.
  static void addSelectionActions(
    List<ContextMenuButtonItem> items,
    List<SelectionAction> actions, {
    required bool hasSelection,
    required Future<List<PdfSelection>> Function() selection,
    required VoidCallback dismiss,
  }) {
    if (!hasSelection || actions.isEmpty) return;
    items.insertAll(0, [
      for (final a in actions)
        ContextMenuButtonItem(
          label: a.label,
          onPressed: () async {
            final selected = await selection();
            dismiss();
            a.onSelected(selected);
          },
        ),
    ]);
  }

  @override
  Stream<PageText> pageTexts(String path) async* {
    final document = await _open(path);
    try {
      for (final page in document.pages) {
        final text = await page.loadStructuredText();
        yield PageText(page: page.pageNumber, text: text.fullText);
      }
    } finally {
      await document.dispose();
    }
  }

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
