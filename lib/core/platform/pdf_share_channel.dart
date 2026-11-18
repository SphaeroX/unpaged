import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hands a PDF to the system: the share sheet ("Share") or the print
/// dialog ("Print"). The app itself sends nothing anywhere; the user picks
/// the target in the system dialog. See `MainActivity.kt`.
class PdfShareChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'io.github.sphaerox.unpaged/share_pdf';

  final MethodChannel _channel;

  /// Opens the share sheet for the PDF at [path]; recipients see [name].
  /// `false` if no app can receive it.
  Future<bool> share(String path, {required String name}) =>
      _invoke('share', path, name);

  /// Opens the system print dialog for the PDF at [path] as job [name].
  /// `false` if printing is not available.
  Future<bool> print(String path, {required String name}) =>
      _invoke('print', path, name);

  Future<bool> _invoke(String method, String path, String name) async {
    try {
      final ok = await _channel.invokeMethod<bool>(method, {
        'path': path,
        'name': name,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false; // Not on Android (tests, other platforms).
    } on PlatformException {
      return false;
    }
  }

  /// A safe PDF file name for a book [title].
  static String fileNameFor(String title) {
    final base = title.trim().replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    if (base.isEmpty) return 'document.pdf';
    return base.toLowerCase().endsWith('.pdf') ? base : '$base.pdf';
  }
}

final pdfShareChannelProvider = Provider<PdfShareChannel>(
  (ref) => PdfShareChannel(),
);
