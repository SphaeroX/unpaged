import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/files/book_file_store.dart';
import 'package:unpaged/core/files/pdf_picker.dart';
import 'package:unpaged/core/files/pdf_source.dart';
import 'package:unpaged/core/platform/incoming_pdf_channel.dart';
import 'package:unpaged/features/import/domain/import_service.dart';
import 'package:unpaged/features/progress/data/reading_position_repository.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';
import 'package:unpaged/features/reflow/domain/reflow_scheduler.dart';
import 'package:unpaged/features/viewer/presentation/viewer_screen.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

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

  /// Continues where reading stopped, in the view used last.
  Future<void> _open(Book book) async {
    final path = ref.read(bookFileStoreProvider).fileFor(book.id).path;
    final last = await ref
        .read(readingPositionRepositoryProvider)
        .lastUsed(book.id);
    if (!mounted) return;
    final ebook =
        last?.view == ReadingView.ebook &&
        book.reflowStatus == ReflowStatus.done;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ebook
            ? ReaderScreen(bookId: book.id, title: book.title)
            : ViewerScreen(
                path: path,
                title: book.title,
                bookId: book.id,
                initialPage: last?.view == ReadingView.original
                    ? last!.page
                    : 1,
              ),
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
                    subtitle: _BookStatus(
                      book: book,
                      progress: ref
                          .watch(readingProgressProvider)
                          .value?[book.id],
                    ),
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
  const new({required this.book, this.progress});

  final Book book;

  /// Reading progress 0..1, if the book was opened before.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final read = progress;
    final pages = read == null
        ? l10n.pageCount(book.pageCount)
        : '${l10n.pageCount(book.pageCount)} · '
              '${l10n.readProgress((read * 100).round())}';
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
