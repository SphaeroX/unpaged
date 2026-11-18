import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/reader/presentation/reader_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

/// Opens a PDF by path once and exposes its [PdfInfo].
final FutureProviderFamily<PdfInfo, String> _pdfInfoProvider = FutureProvider
    .autoDispose
    .family<PdfInfo, String>(
      (ref, path) => ref.watch(pdfAdapterProvider).inspect(path),
    );

/// Original page view of a single PDF.
class ViewerScreen extends ConsumerWidget {
  const new({required this.path, this.title, this.bookId, super.key});

  final String path;

  /// Shown in the app bar; defaults to the app name.
  final String? title;

  /// Library book shown here; enables switching to the eBook view.
  final String? bookId;

  void _switchToEbook(BuildContext context, WidgetRef ref, Book? book) {
    final l10n = AppLocalizations.of(context);
    if (book == null || book.reflowStatus != ReflowStatus.done) {
      final message = switch (book?.reflowStatus) {
        ReflowStatus.running => l10n.reflowRunning(
          ((book?.reflowProgress ?? 0) * 100).round(),
        ),
        ReflowStatus.failed => l10n.reflowFailed,
        ReflowStatus.noText => l10n.reflowNoText,
        _ => l10n.ebookNotReady,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(bookId: book.id, title: book.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(_pdfInfoProvider(path));
    final id = bookId;
    final book = id == null ? null : ref.watch(bookProvider(id)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.appTitle),
        actions: [
          if (id != null)
            IconButton(
              tooltip: l10n.switchToEbook,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _switchToEbook(context, ref, book),
            ),
        ],
      ),
      body: info.when(
        data: (_) => ref.read(pdfAdapterProvider).pageView(path),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.pdfOpenError, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
