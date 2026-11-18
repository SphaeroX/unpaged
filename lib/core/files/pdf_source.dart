import 'dart:io';
import 'dart:typed_data';

/// A PDF handed to the app (file picker, "Open with", "Share").
abstract class PdfSource {
  /// File name as shown to the user, e.g. `paper.pdf`.
  String get name;

  Future<Uint8List> readBytes();
}

/// A PDF available as a local file.
class FilePdfSource implements PdfSource {
  new(this.path, {String? name})
    : name = name ?? path.split(Platform.pathSeparator).last;

  final String path;

  @override
  final String name;

  @override
  Future<Uint8List> readBytes() => File(path).readAsBytes();
}
