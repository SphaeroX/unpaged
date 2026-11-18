import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/pdf/pdfrx_adapter.dart';

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

/// The only gateway to the PDF engine. Features never import pdfrx directly.
abstract class PdfAdapter {
  /// Opens the PDF at [path] and returns basic facts.
  ///
  /// Throws [PdfOpenException] if the file cannot be read as a PDF.
  Future<PdfInfo> inspect(String path);

  /// Widget showing the original pages of the PDF at [path].
  Widget pageView(String path);
}

final pdfAdapterProvider = Provider<PdfAdapter>((ref) => PdfrxAdapter());
