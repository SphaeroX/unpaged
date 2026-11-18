import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/files/pdf_source.dart';

/// PDFs handed to the app by Android ("Open with", "Share").
///
/// The Android side copies the shared content into the app's cache and
/// reports the copy's path; see `MainActivity.kt`.
class IncomingPdfChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pdfReceived') {
        final source = _source(call.arguments);
        if (source != null) _received.add(source);
      }
    });
  }

  static const channelName = 'dev.paperflow/incoming_pdf';

  final MethodChannel _channel;
  final _received = StreamController<PdfSource>.broadcast();

  /// PDFs arriving while the app runs.
  Stream<PdfSource> get received => _received.stream;

  /// The PDF the app was started with, if any.
  Future<PdfSource?> initial() async {
    try {
      return _source(await _channel.invokeMethod<Object?>('getInitialPdf'));
    } on MissingPluginException {
      return null; // Not on Android (tests, other platforms).
    }
  }

  static PdfSource? _source(Object? args) {
    if (args is! Map) return null;
    final path = args['path'];
    final name = args['name'];
    if (path is! String) return null;
    return FilePdfSource(path, name: name is String ? name : null);
  }

  Future<void> dispose() => _received.close();
}

final incomingPdfChannelProvider = Provider<IncomingPdfChannel>((ref) {
  final channel = IncomingPdfChannel();
  ref.onDispose(channel.dispose);
  return channel;
});
