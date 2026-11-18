import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user choose a PDF from the device.
abstract class PdfPicker {
  /// Returns the path of the chosen PDF, or `null` if the user cancelled.
  Future<String?> pickPdf();
}

class FilePickerPdfPicker implements PdfPicker {
  @override
  Future<String?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    return file?.path;
  }
}

final pdfPickerProvider = Provider<PdfPicker>((ref) => FilePickerPdfPicker());
