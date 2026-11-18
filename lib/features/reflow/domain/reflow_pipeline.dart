import 'dart:isolate';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// Runs the reflow engine; by default in a background isolate.
typedef EngineRunner = Future<ReflowDocument> Function(DocumentInput input);

Future<ReflowDocument> runEngineInIsolate(DocumentInput input) =>
    Isolate.run(() => const ReflowEngine().reflow(input));

/// Below this many glyphs per page a PDF counts as having no text layer
/// (scans); it is shown in the original view only.
const _minCharsPerPage = 20;

/// Extract text → reflow → render region crops → cache, with progress and
/// status in the database.
class ReflowPipeline {
  new({
    required this.db,
    required this.books,
    required this.store,
    required this.adapter,
    EngineRunner? runEngine,
  }) : _runEngine = runEngine ?? runEngineInIsolate;

  final AppDatabase db;
  final BookFileStore books;
  final ReflowStore store;
  final PdfAdapter adapter;
  final EngineRunner _runEngine;

  /// Whether [book] has to be (re)computed: never finished, interrupted,
  /// or computed by an older engine. Failures are not retried automatically.
  Future<bool> needsWork(Book book) async {
    switch (book.reflowStatus) {
      case ReflowStatus.pending:
      case ReflowStatus.running:
        return true;
      case ReflowStatus.failed:
      case ReflowStatus.noText:
        return false;
      case ReflowStatus.done:
        final version = await store.storedVersion(book.id);
        return version == null || version < ReflowEngine.version;
    }
  }

  Future<void> process(String bookId) async {
    await _set(bookId, ReflowStatus.running, 0);
    try {
      final path = books.fileFor(bookId).path;
      final input = await adapter.extractText(path);
      final chars = input.pages.fold<int>(0, (n, p) => n + p.chars.length);
      if (chars < _minCharsPerPage * input.pages.length.clamp(1, 1 << 30)) {
        await _set(bookId, ReflowStatus.noText, 1);
        return;
      }
      await _set(bookId, ReflowStatus.running, 0.3);

      final doc = await _runEngine(input);
      await _set(bookId, ReflowStatus.running, 0.6);

      final regions = doc.blocks.where((b) => b.type.isRegion).toList();
      if (regions.isNotEmpty) {
        final pngs = await adapter.renderRegions(path, [
          for (final r in regions) RegionRequest(page: r.page, box: r.box),
        ]);
        for (var i = 0; i < regions.length; i++) {
          await store.writeCrop(bookId, regions[i].id, pngs[i]);
        }
      }
      await _set(bookId, ReflowStatus.running, 0.9);

      await store.writeDocument(bookId, doc);
      await _set(bookId, ReflowStatus.done, 1);
    } on Object {
      await store.delete(bookId);
      await _set(bookId, ReflowStatus.failed, 1);
    }
  }

  Future<void> _set(String id, ReflowStatus status, double progress) =>
      (db.update(db.books)..where((b) => b.id.equals(id))).write(
        BooksCompanion(
          reflowStatus: Value(status),
          reflowProgress: Value(progress),
        ),
      );
}

final reflowPipelineProvider = Provider<ReflowPipeline>(
  (ref) => ReflowPipeline(
    db: ref.watch(databaseProvider),
    books: ref.watch(bookFileStoreProvider),
    store: ref.watch(reflowStoreProvider),
    adapter: ref.watch(pdfAdapterProvider),
  ),
);
