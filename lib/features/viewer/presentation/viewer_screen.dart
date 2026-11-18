import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/features/progress/data/reading_position_repository.dart';
import 'package:paperflow/features/progress/domain/reading_position.dart';
import 'package:paperflow/features/reader/presentation/reader_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

/// Opens a PDF by path once and exposes its [PdfInfo].
final FutureProviderFamily<PdfInfo, String> _pdfInfoProvider = FutureProvider
    .autoDispose
    .family<PdfInfo, String>(
      (ref, path) => ref.watch(pdfAdapterProvider).inspect(path),
    );

/// Original page view of a single PDF.
class ViewerScreen extends ConsumerStatefulWidget {
  const new({
    required this.path,
    this.title,
    this.bookId,
    this.initialPage = 1,
    super.key,
  });

  final String path;

  /// Shown in the app bar; defaults to the app name.
  final String? title;

  /// Library book shown here; enables switching views and saving progress.
  final String? bookId;

  final int initialPage;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late int _page = widget.initialPage;

  void _onPageChanged(int page, int pageCount) {
    _page = page;
    final id = widget.bookId;
    if (id == null) return;
    unawaited(
      ref
          .read(readingPositionRepositoryProvider)
          .save(
            id,
            ReadingPosition(
              view: ReadingView.original,
              page: page,
              progress: originalProgress(page: page, pageCount: pageCount),
            ),
          ),
    );
  }

  void _switchToEbook(Book? book) {
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
        builder: (_) => ReaderScreen(
          bookId: book.id,
          title: book.title,
          initialPage: _page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(_pdfInfoProvider(widget.path));
    final id = widget.bookId;
    final book = id == null ? null : ref.watch(bookProvider(id)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l10n.appTitle),
        actions: [
          if (id != null)
            IconButton(
              tooltip: l10n.switchToEbook,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _switchToEbook(book),
            ),
        ],
      ),
      body: info.when(
        data: (info) => ref
            .read(pdfAdapterProvider)
            .pageView(
              widget.path,
              initialPage: widget.initialPage,
              onPageChanged: (p) => _onPageChanged(p, info.pageCount),
            ),
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
