import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's source code; linked from the app bar.
const gitHubUrl = 'https://github.com/SphaeroX/unpaged';

/// Opens a web link in the user's browser. The app itself loads nothing
/// from the network; the browser does. See `ExternalLink.kt`.
class ExternalLinkChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'io.github.sphaerox.unpaged/links';

  final MethodChannel _channel;

  /// Opens [url] in the browser; `false` if no app can show it.
  Future<bool> open(String url) async {
    try {
      return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
    } on MissingPluginException {
      return false; // Not on Android (tests, other platforms).
    } on PlatformException {
      return false;
    }
  }
}

final externalLinkChannelProvider = Provider<ExternalLinkChannel>(
  (ref) => ExternalLinkChannel(),
);
