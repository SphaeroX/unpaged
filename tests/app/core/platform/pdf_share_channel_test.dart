import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/platform/pdf_share_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(PdfShareChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('share() hands path and file name to the platform', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final ok = await PdfShareChannel(channel)
        .share('/books/abc.pdf', name: 'Paper.pdf');

    expect(ok, isTrue);
    expect(received?.method, 'share');
    expect(received?.arguments, {
      'path': '/books/abc.pdf',
      'name': 'Paper.pdf',
    });
  });

  test('print() hands path and job name to the platform', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final ok = await PdfShareChannel(channel)
        .print('/books/abc.pdf', name: 'Paper.pdf');

    expect(ok, isTrue);
    expect(received?.method, 'print');
    expect(received?.arguments, {
      'path': '/books/abc.pdf',
      'name': 'Paper.pdf',
    });
  });

  test('is false when the platform side is missing', () async {
    final share = PdfShareChannel(channel);

    expect(await share.share('/a.pdf', name: 'a.pdf'), isFalse);
    expect(await share.print('/a.pdf', name: 'a.pdf'), isFalse);
  });

  test('is false when the platform reports an error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'no_app');
    });

    expect(
      await PdfShareChannel(channel).share('/a.pdf', name: 'a.pdf'),
      isFalse,
    );
  });

  test('fileNameFor() turns a title into a safe PDF file name', () {
    expect(PdfShareChannel.fileNameFor('Paper'), 'Paper.pdf');
    expect(PdfShareChannel.fileNameFor('report.pdf'), 'report.pdf');
    expect(PdfShareChannel.fileNameFor('a/b:c'), 'a_b_c.pdf');
    expect(PdfShareChannel.fileNameFor('  '), 'document.pdf');
  });
}
