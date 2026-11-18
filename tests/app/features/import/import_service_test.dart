import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/files/pdf_source.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/import/domain/import_service.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';

class _MockAdapter extends Mock implements PdfAdapter;

class _BytesSource implements PdfSource {
  new(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Future<Uint8List> readBytes() async => bytes;
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BookFileStore store;
  late _MockAdapter adapter;
  late ImportService service;

  final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 fake'));
  final sha = sha256.convert(pdfBytes).toString();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('paperflow_import');
    store = BookFileStore(dir);
    adapter = _MockAdapter();
    when(() => adapter.inspect(any()))
        .thenAnswer((_) async => const PdfInfo(pageCount: 12));
    service = ImportService(db: db, store: store, adapter: adapter);
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('copies the PDF to books/<sha256>.pdf and adds an entry', () async {
    final result = await service.importPdf(
      _BytesSource('My_Paper-v2.pdf', pdfBytes),
    );

    expect(result, isA<ImportSuccess>());
    final file = File('${dir.path}/books/$sha.pdf');
    expect(file.readAsBytesSync(), pdfBytes);
    final book = (await db.select(db.books).get()).single;
    expect(book.id, sha);
    expect(book.title, 'My Paper-v2');
    expect(book.pageCount, 12);
    verify(() => adapter.inspect(file.path)).called(1);
  });

  test('a second import of the same bytes reports a duplicate', () async {
    await service.importPdf(_BytesSource('a.pdf', pdfBytes));

    final result = await service.importPdf(_BytesSource('b.pdf', pdfBytes));

    expect(result, isA<ImportDuplicate>());
    expect((result as ImportDuplicate).book.id, sha);
    expect(await db.select(db.books).get(), hasLength(1));
  });

  test('an unreadable PDF fails without leaving an entry or file', () async {
    when(() => adapter.inspect(any()))
        .thenThrow(const PdfOpenException('damaged'));

    final result = await service.importPdf(_BytesSource('x.pdf', pdfBytes));

    expect(result, isA<ImportFailure>());
    expect(await db.select(db.books).get(), isEmpty);
    expect(File('${dir.path}/books/$sha.pdf').existsSync(), isFalse);
  });

  test('a file that does not start like a PDF fails early', () async {
    final result = await service.importPdf(
      _BytesSource('notes.txt', Uint8List.fromList(utf8.encode('hello'))),
    );

    expect(result, isA<ImportFailure>());
    verifyNever(() => adapter.inspect(any()));
  });

  test('delete removes the entry and the file', () async {
    await service.importPdf(_BytesSource('a.pdf', pdfBytes));

    await service.deleteBook(sha);

    expect(await db.select(db.books).get(), isEmpty);
    expect(File('${dir.path}/books/$sha.pdf').existsSync(), isFalse);
  });

  test('delete also removes the reflow cache of the book', () async {
    final reflow = ReflowStore(dir);
    final withCache = ImportService(
      db: db,
      store: store,
      adapter: adapter,
      reflowStore: reflow,
    );
    await withCache.importPdf(_BytesSource('a.pdf', pdfBytes));
    await reflow.writeCrop(sha, 'p1b0', Uint8List(1));

    await withCache.deleteBook(sha);

    expect(Directory('${dir.path}/reflow/$sha').existsSync(), isFalse);
  });

  test('delete tolerates a missing file', () async {
    await service.importPdf(_BytesSource('a.pdf', pdfBytes));
    File('${dir.path}/books/$sha.pdf').deleteSync();

    await service.deleteBook(sha);

    expect(await db.select(db.books).get(), isEmpty);
  });
}
