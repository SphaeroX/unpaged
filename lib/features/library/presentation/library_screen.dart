import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/files/pdf_picker.dart';
import 'package:paperflow/core/files/pdf_source.dart';
import 'package:paperflow/core/platform/incoming_pdf_channel.dart';
import 'package:paperflow/features/import/domain/import_service.dart';
import 'package:paperflow/features/reflow/domain/reflow_scheduler.dart';
import 'package:paperflow/features/viewer/presentation/viewer_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

final booksProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(databaseProvider).watchBooks(),
);

/// Start screen: imported books, import button, delete.
class LibraryScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  StreamSubscription<PdfSource>? _incoming;

  @override
  void initState() {
    super.initState();
    final channel = ref.read(incomingPdfChannelProvider);
    _incoming = channel.received.listen(_import);
    // Resume interrupted runs and recompute results of older engines.
    unawaited(ref.read(reflowSchedulerProvider).start());
    unawaited(channel.initial().then((s) => s == null ? null : _import(s)));
  }

  @override
  void dispose() {
    unawaited(_incoming?.cancel());
    super.dispose();
  }

  Future<void> _pick() async {
    final source = await ref.read(pdfPickerProvider).pickPdf();
    if (source != null) await _import(source);
  }

  Future<void> _import(PdfSource source) async {
    final result = await ref.read(importServiceProvider).importPdf(source);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case ImportSuccess(:final book):
        ref.read(reflowSchedulerProvider).enqueue(book.id);
        await _open(book);
      case ImportDuplicate(:final book):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.alreadyInLibrary)));
        await _open(book);
      case ImportFailure():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.pdfOpenError)));
    }
  }

  Future<void> _open(Book book) async {
    final path = ref.read(bookFileStoreProvider).fileFor(book.id).path;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ViewerScreen(path: path, title: book.title, bookId: book.id),
      ),
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle(book.title)),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteBook),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(importServiceProvider).deleteBook(book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pick,
        icon: const Icon(Icons.file_open),
        label: Text(l10n.openPdf),
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (books) => books.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.libraryEmpty, textAlign: TextAlign.center),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: books.length,
                itemBuilder: (context, i) {
                  final book = books[i];
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(book.title),
                    subtitle: _BookStatus(book: book),
                    onTap: () => _open(book),
                    trailing: IconButton(
                      tooltip: l10n.deleteBook,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(book),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Page count plus the state of the eBook preparation.
class _BookStatus extends StatelessWidget {
  const new({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = l10n.pageCount(book.pageCount);
    final status = switch (book.reflowStatus) {
      ReflowStatus.running => l10n.reflowRunning(
        (book.reflowProgress * 100).round(),
      ),
      ReflowStatus.failed => l10n.reflowFailed,
      ReflowStatus.noText => l10n.reflowNoText,
      ReflowStatus.pending || ReflowStatus.done => null,
    };
    final running = book.reflowStatus == ReflowStatus.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status == null ? pages : '$pages · $status'),
        if (running)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(value: book.reflowProgress),
          ),
      ],
    );
  }
}
