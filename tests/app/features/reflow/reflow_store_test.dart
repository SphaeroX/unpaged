import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';
import 'package:reflow_engine/reflow_engine.dart';

void main() {
  late Directory dir;
  late ReflowStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('paperflow_reflow');
    store = ReflowStore(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  const doc = ReflowDocument(
    engineVersion: 3,
    blocks: [
      ReflowBlock(
        id: 'p1b0',
        type: BlockType.paragraph,
        text: 'Hello',
        page: 1,
        box: BBox(1, 2, 3, 4),
      ),
    ],
  );

  test('writes and reads the document JSON', () async {
    await store.writeDocument('abc', doc);

    expect(await store.readDocument('abc'), doc);
    expect(File('${dir.path}/reflow/abc/document.json').existsSync(), isTrue);
  });

  test('reading a missing or broken document returns null', () async {
    expect(await store.readDocument('none'), isNull);
    File('${dir.path}/reflow/bad/document.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');
    expect(await store.readDocument('bad'), isNull);
  });

  test('stores crops per block id', () async {
    await store.writeCrop('abc', 'p2b3', Uint8List.fromList([1, 2, 3]));

    expect(store.cropFile('abc', 'p2b3').readAsBytesSync(), [1, 2, 3]);
    expect(
      store.cropFile('abc', 'p2b3').path,
      endsWith('reflow/abc/crops/p2b3.png'),
    );
  });

  test('delete removes everything of a book', () async {
    await store.writeDocument('abc', doc);
    await store.writeCrop('abc', 'p1b0', Uint8List(1));

    await store.delete('abc');

    expect(Directory('${dir.path}/reflow/abc').existsSync(), isFalse);
    await store.delete('abc'); // missing is fine
  });
}
