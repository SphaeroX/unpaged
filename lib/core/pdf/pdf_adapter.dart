import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/pdf/pdfrx_adapter.dart';
import 'package:reflow_engine/reflow_engine.dart';

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

  /// Widget showing the original pages of the PDF at [path].
  Widget pageView(String path);
}

final pdfAdapterProvider = Provider<PdfAdapter>((ref) => PdfrxAdapter());
