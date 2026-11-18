import 'package:flutter/widgets.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:pdfrx/pdfrx.dart';

/// [PdfAdapter] backed by pdfrx (PDFium).
class PdfrxAdapter implements PdfAdapter {
  @override
  Future<PdfInfo> inspect(String path) async {
    final PdfDocument document;
    try {
      document = await PdfDocument.openFile(path);
    } on Object catch (e) {
      throw PdfOpenException(e.toString());
    }
    try {
      return PdfInfo(pageCount: document.pages.length);
    } finally {
      await document.dispose();
    }
  }

  @override
  Widget pageView(String path) => PdfViewer.file(path);
}
