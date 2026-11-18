import 'dart:async';
import 'dart:collection';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/features/reflow/domain/reflow_pipeline.dart';

/// Background reflow work as seen by the UI.
abstract interface class ReflowQueue {
  /// Completes when no work is pending.
  Future<void> get idle;

  /// Queues every book that still needs work.
  Future<void> start();

  void enqueue(String bookId);
}

/// Runs the reflow pipeline for one book after another in the background.
class ReflowScheduler implements ReflowQueue {
  new({required this.db, required this.pipeline});

  final AppDatabase db;
  final ReflowPipeline pipeline;

  final _queue = Queue<String>();
  Completer<void>? _running;

  @override
  Future<void> get idle => _running?.future ?? Future.value();

  /// Queues every book that still needs work (new, interrupted, or computed
  /// by an older engine), oldest import first.
  @override
  Future<void> start() async {
    final books = await (db.select(
      db.books,
    )..orderBy([(b) => OrderingTerm.asc(b.importedAt)])).get();
    for (final book in books) {
      if (await pipeline.needsWork(book)) enqueue(book.id);
    }
  }

  @override
  void enqueue(String bookId) {
    if (_queue.contains(bookId)) return;
    _queue.add(bookId);
    if (_running == null) unawaited(_drain());
  }

  Future<void> _drain() async {
    final done = _running = Completer<void>();
    try {
      while (_queue.isNotEmpty) {
        await pipeline.process(_queue.first);
        _queue.removeFirst();
      }
    } finally {
      _running = null;
      done.complete();
    }
  }
}

/// Does nothing; used where background work is unwanted (widget tests).
class NoopReflowScheduler implements ReflowQueue {
  @override
  Future<void> get idle => Future.value();

  @override
  Future<void> start() async {}

  @override
  void enqueue(String bookId) {}
}

final reflowSchedulerProvider = Provider<ReflowQueue>(
  (ref) => ReflowScheduler(
    db: ref.watch(databaseProvider),
    pipeline: ref.watch(reflowPipelineProvider),
  ),
);
