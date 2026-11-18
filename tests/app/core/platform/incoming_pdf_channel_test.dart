import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/files/pdf_source.dart';
import 'package:unpaged/core/platform/incoming_pdf_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(IncomingPdfChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('initial() returns the PDF the app was started with', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInitialPdf');
      return {'path': '/cache/incoming/paper.pdf', 'name': 'paper.pdf'};
    });

    final source = await IncomingPdfChannel(channel).initial();

    expect(source, isA<FilePdfSource>());
    expect((source! as FilePdfSource).path, '/cache/incoming/paper.pdf');
    expect(source.name, 'paper.pdf');
  });

  test('initial() is null when nothing was shared', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await IncomingPdfChannel(channel).initial(), isNull);
  });

  test('initial() is null when the platform side is missing', () async {
    expect(await IncomingPdfChannel(channel).initial(), isNull);
  });

  test('PDFs shared while running arrive on the stream', () async {
    final incoming = IncomingPdfChannel(channel);
    final next = incoming.received.first;

    await messenger.handlePlatformMessage(
      IncomingPdfChannel.channelName,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('pdfReceived', {'path': '/c/b.pdf', 'name': 'b.pdf'}),
      ),
      (_) {},
    );

    expect((await next).name, 'b.pdf');
  });
}
