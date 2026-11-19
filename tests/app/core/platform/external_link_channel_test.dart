import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unpaged/core/platform/external_link_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ExternalLinkChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('open() hands the URL to the platform', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final ok = await ExternalLinkChannel(channel).open(gitHubUrl);

    expect(ok, isTrue);
    expect(received?.method, 'open');
    expect(received?.arguments, {'url': gitHubUrl});
  });

  test('points to the public repository', () {
    expect(gitHubUrl, 'https://github.com/SphaeroX/unpaged');
  });

  test('is false when the platform side is missing', () async {
    expect(await ExternalLinkChannel(channel).open(gitHubUrl), isFalse);
  });

  test('is false when the platform reports an error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'no_app');
    });

    expect(await ExternalLinkChannel(channel).open(gitHubUrl), isFalse);
  });
}
