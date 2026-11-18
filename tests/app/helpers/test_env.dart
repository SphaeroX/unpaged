import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/files/pdf_source.dart';

/// In-memory database and a temporary book directory for widget tests.
class TestEnv {
  new()
    : db = AppDatabase(NativeDatabase.memory()),
      dir = Directory.systemTemp.createTempSync('paperflow_test') {
    store = BookFileStore(dir);
  }

  final AppDatabase db;
  final Directory dir;
  late final BookFileStore store;

  List<dynamic> get overrides => [
    databaseProvider.overrideWithValue(db),
    bookFileStoreProvider.overrideWithValue(store),
  ];

  /// Unmounts the app and lets drift's stream timers run out. Call at the
  /// end of every widget test that used this environment.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Safe in `tearDown`: does not wait for drift (whose close needs timers
  /// that never fire outside the widget test's fake clock).
  void dispose() {
    unawaited(db.close());
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// A tiny byte sequence that passes the "%PDF" check.
Uint8List fakePdf([String marker = 'a']) =>
    Uint8List.fromList(utf8.encode('%PDF-1.4 $marker'));

class BytesPdfSource implements PdfSource {
  new(this.name, this.bytes);

  @override
  final String name;
  final Uint8List bytes;

  @override
  Future<Uint8List> readBytes() async => bytes;
}

/// Lets real file I/O (outside the fake-async zone) finish, then settles.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}
