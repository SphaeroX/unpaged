import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reflow_engine/reflow_engine.dart';
import 'package:unpaged/core/pdf/pdfrx_adapter.dart';

/// Basic facts about an opened PDF.
@immutable
class PdfInfo {
  const new({required this.pageCount});

  final int pageCount;
}

/// Thrown when a PDF cannot be opened (missing, damaged, encrypted, ...).
class PdfOpenException implements Exception {
  const new(this.reason);

  final String reason;

  @override
  String toString() => 'PdfOpenException: $reason';
}

/// A rectangle of a page to render as an image.
@immutable
class RegionRequest {
  const new({required this.page, required this.box});

  /// 1-based page number.
  final int page;

  /// Area in top-down page points.
  final BBox box;
}

/// Selected text on one page: PDFium character range [start]..[end).
@immutable
class PdfSelection {
  const new({
    required this.page,
    required this.start,
    required this.end,
    required this.text,
  });

  final int page;
  final int start;
  final int end;
  final String text;
}

/// A highlight to draw: boxes in top-down page points.
@immutable
class PageHighlight {
  const new({
    required this.id,
    required this.page,
    required this.rects,
    required this.argb,
  });

  final int id;
  final int page;
  final List<BBox> rects;
  final int argb;
}

/// An entry of the selection context menu.
@immutable
class SelectionAction {
  const new({required this.label, required this.onSelected});

  final String label;
  final void Function(List<PdfSelection> selection) onSelected;
}

/// The text of one page; offsets match [PdfAdapter.textRects].
@immutable
class PageText {
  const new({required this.page, required this.text});

  /// 1-based page number.
  final int page;
  final String text;
}

/// Steers a [PdfAdapter.pageView]: the screen owns it for as long as it
/// shows the view, the adapter connects it to its viewer.
class PageViewController {
  /// Set by the adapter when it builds the view.
  Future<void> Function(int page)? goToHandler;

  /// Scrolls to [page] (1-based); does nothing before the view is shown.
  Future<void> goToPage(int page) async {
    await goToHandler?.call(page);
  }
}

/// The only gateway to the PDF engine. Features never import pdfrx directly.
abstract class PdfAdapter {
  /// Opens the PDF at [path] and returns basic facts.
  ///
  /// Throws [PdfOpenException] if the file cannot be read as a PDF.
  Future<PdfInfo> inspect(String path);

  /// Extracts the visible glyphs of every page for the reflow engine.
  ///
  /// Coordinates are converted to top-down page points. Throws
  /// [PdfOpenException] if the file cannot be read as a PDF.
  Future<DocumentInput> extractText(String path);

  /// Renders each region as a PNG at [scale] pixels per point.
  Future<List<Uint8List>> renderRegions(
    String path,
    List<RegionRequest> regions, {
    double scale = 3,
  });

  /// Widget showing the original pages of the PDF at [path], starting at
  /// [initialPage]; [onPageChanged] reports the current page (1-based).
  /// With a [controller] the view gets a draggable scroll thumb for fast
  /// scrolling and can be moved to a page.
  Widget pageView(
    String path, {
    PageViewController? controller,
    int initialPage = 1,
    ValueChanged<int>? onPageChanged,
    List<PageHighlight> highlights = const [],
    List<SelectionAction> selectionActions = const [],
    ValueChanged<int>? onHighlightTap,
  });

  /// The text of every page, page by page (for searching).
  ///
  /// Throws [PdfOpenException] if the file cannot be read as a PDF.
  Stream<PageText> pageTexts(String path);

  /// Boxes (one per line, top-down page points) covering the characters
  /// [start]..[end) of [page].
  Future<List<BBox>> textRects(
    String path, {
    required int page,
    required int start,
    required int end,
  });
}

final pdfAdapterProvider = Provider<PdfAdapter>((ref) => PdfrxAdapter());
