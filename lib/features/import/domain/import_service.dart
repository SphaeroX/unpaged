import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/files/pdf_source.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';

sealed class ImportResult {
  const new();
}

class ImportSuccess extends ImportResult {
  const new(this.book);
  final Book book;
}

class ImportDuplicate extends ImportResult {
  const new(this.book);
  final Book book;
}

class ImportFailure extends ImportResult {
  const new(this.reason);
  final String reason;
}

/// Copies PDFs into the app, deduplicated by SHA-256, and removes them.
class ImportService {
  new({
    required this.db,
    required this.store,
    required this.adapter,
    this.reflowStore,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Cached reflow results, removed together with the book.
  final ReflowStore? reflowStore;

  final AppDatabase db;
  final BookFileStore store;
  final PdfAdapter adapter;
  final DateTime Function() _clock;

  Future<ImportResult> importPdf(PdfSource source) async {
    final Uint8List bytes;
    try {
      bytes = await source.readBytes();
    } on Object catch (e) {
      return ImportFailure('unreadable: $e');
    }
    if (!_looksLikePdf(bytes)) return const ImportFailure('not a PDF');

    final id = sha256.convert(bytes).toString();
    final existing = await db.bookById(id);
    if (existing != null) return ImportDuplicate(existing);

    final file = await store.write(id, bytes);
    final PdfInfo info;
    try {
      info = await adapter.inspect(file.path);
    } on PdfOpenException catch (e) {
      await store.delete(id);
      return ImportFailure(e.reason);
    }

    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            title: titleFromFileName(source.name),
            pageCount: info.pageCount,
            importedAt: _clock(),
          ),
        );
    return ImportSuccess((await db.bookById(id))!);
  }

  Future<void> deleteBook(String id) async {
    await (db.delete(db.books)..where((b) => b.id.equals(id))).go();
    await (db.delete(
      db.readingPositions,
    )..where((p) => p.bookId.equals(id))).go();
    await store.delete(id);
    await reflowStore?.delete(id);
  }

  static bool _looksLikePdf(Uint8List bytes) {
    final head = String.fromCharCodes(bytes.take(1024));
    return head.contains('%PDF');
  }

  /// `My_Paper-v2.pdf` → `My Paper-v2`.
  static String titleFromFileName(String name) {
    final base = name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final title = base.replaceAll('_', ' ').trim();
    return title.isEmpty ? name : title;
  }
}

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    db: ref.watch(databaseProvider),
    store: ref.watch(bookFileStoreProvider),
    adapter: ref.watch(pdfAdapterProvider),
    reflowStore: ref.watch(reflowStoreProvider),
  ),
);
