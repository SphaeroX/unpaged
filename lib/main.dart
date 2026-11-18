import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unpaged/app.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/features/reflow/data/reflow_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await getApplicationSupportDirectory();
  runApp(
    ProviderScope(
      overrides: [
        bookFileStoreProvider.overrideWithValue(BookFileStore(storage)),
        reflowStoreProvider.overrideWithValue(ReflowStore(storage)),
      ],
      child: const UnpagedApp(),
    ),
  );
}
