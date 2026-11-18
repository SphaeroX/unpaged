import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/core/pdf/pdfrx_adapter.dart';
import 'package:unpaged/features/reflow/data/reflow_store.dart';
import 'package:unpaged/features/reflow/domain/reflow_pipeline.dart';

/// On a device: a real PDF goes through extraction, the engine in a
/// background isolate and storage (Task 06), checking that this works on
/// Android and not only on the host.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('processes a PDF to done with a stored document', (tester) async {
    await pdfrxFlutterInitialize();
    final tmp = Directory.systemTemp.createTempSync('unpaged_it_reflow');
    final db = AppDatabase(NativeDatabase.memory());
    final books = BookFileStore(tmp);
    final store = ReflowStore(tmp);
    await books.write('book', base64Decode(_pdf));
    await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            id: 'book',
            title: 'Test',
            pageCount: 1,
            importedAt: DateTime.now(),
          ),
        );

    await ReflowPipeline(
      db: db,
      books: books,
      store: store,
      adapter: PdfrxAdapter(),
    ).process('book');

    final book = await db.bookById('book');
    expect(book!.reflowStatus, isNot(ReflowStatus.failed));
    expect(await store.readDocument('book'), isNotNull);
    await db.close();
  });
}

/// tests/reflow_engine/corpus/synthetic_single_column.pdf (CC0), inlined.
const _pdf =
    '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';
