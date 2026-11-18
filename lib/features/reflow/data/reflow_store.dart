import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// Cached reflow results: `<root>/reflow/<book id>/document.json` and
/// `<root>/reflow/<book id>/crops/<block id>.png`.
class ReflowStore {
  new(this.root);

  final Directory root;

  Directory _dir(String bookId) => Directory('${root.path}/reflow/$bookId');

  File _documentFile(String bookId) =>
      File('${_dir(bookId).path}/document.json');

  File cropFile(String bookId, String blockId) =>
      File('${_dir(bookId).path}/crops/$blockId.png');

  Future<void> writeDocument(String bookId, ReflowDocument doc) async {
    final file = _documentFile(bookId);
    await file.parent.create(recursive: true);
    // Write atomically so an interrupted run never leaves half a file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(doc.toJson()), flush: true);
    await tmp.rename(file.path);
  }

  /// The stored document, or `null` if missing or unreadable.
  Future<ReflowDocument?> readDocument(String bookId) async {
    final file = _documentFile(bookId);
    if (!file.existsSync()) return null;
    try {
      return ReflowDocument.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  /// Engine version of the stored document without parsing all blocks.
  Future<int?> storedVersion(String bookId) async =>
      (await readDocument(bookId))?.engineVersion;

  Future<void> writeCrop(String bookId, String blockId, Uint8List png) async {
    final file = cropFile(bookId, blockId);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png, flush: true);
  }

  Future<void> delete(String bookId) async {
    final dir = _dir(bookId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// Overridden in `main()` once the app's storage directory is known.
final reflowStoreProvider = Provider<ReflowStore>(
  (ref) => throw UnimplementedError('reflowStoreProvider not configured'),
);
