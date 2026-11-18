import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's own copies of imported PDFs: `<root>/books/<sha256>.pdf`.
class BookFileStore {
  new(this.root);

  final Directory root;

  File fileFor(String id) => File(
    '${root.path}${Platform.pathSeparator}books'
    '${Platform.pathSeparator}$id.pdf',
  );

  Future<File> write(String id, Uint8List bytes) async {
    final file = fileFor(id);
    await file.parent.create(recursive: true);
    return await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> delete(String id) async {
    final file = fileFor(id);
    if (file.existsSync()) await file.delete();
  }
}

/// Overridden in `main()` once the app's storage directory is known.
final bookFileStoreProvider = Provider<BookFileStore>(
  (ref) => throw UnimplementedError('bookFileStoreProvider not configured'),
);
