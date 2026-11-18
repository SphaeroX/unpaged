import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unpaged/core/files/pdf_source.dart';

/// Lets the user choose a PDF from the device.
abstract class PdfPicker {
  /// The chosen PDF, or `null` if the user cancelled.
  Future<PdfSource?> pickPdf();
}

class FilePickerPdfPicker implements PdfPicker {
  @override
  Future<PdfSource?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    return file == null ? null : _PlatformFileSource(file);
  }
}

/// Reads through the platform file, which also works for `content://` URIs.
class _PlatformFileSource implements PdfSource {
  new(this.file);

  final PlatformFile file;

  @override
  String get name => file.name;

  @override
  Future<Uint8List> readBytes() => file.xFile.readAsBytes();
}

final pdfPickerProvider = Provider<PdfPicker>((ref) => FilePickerPdfPicker());
