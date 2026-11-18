import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/app.dart';

/// Builds the full app with the given provider overrides.
Widget buildTestApp({
  // ProviderScope.overrides takes a List of overrides; the element type is
  // not exported under a stable name across Riverpod versions.
  List<dynamic> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: PaperflowApp(locale: locale),
  );
}
