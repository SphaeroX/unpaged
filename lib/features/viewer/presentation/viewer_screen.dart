import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/core/pdf/pdf_adapter.dart';
import 'package:unpaged/features/annotations/data/annotation_repository.dart';
import 'package:unpaged/features/annotations/domain/annotation.dart';
import 'package:unpaged/features/annotations/presentation/annotation_sheets.dart';
import 'package:unpaged/features/progress/data/reading_position_repository.dart';
import 'package:unpaged/features/progress/domain/reading_position.dart';
import 'package:unpaged/features/reader/presentation/reader_screen.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

/// Opens a PDF by path once and exposes its [PdfInfo].
final FutureProviderFamily<PdfInfo, String> _pdfInfoProvider = FutureProvider
    .autoDispose
    .family<PdfInfo, String>(
      (ref, path) => ref.watch(pdfAdapterProvider).inspect(path),
    );

/// Highlights of the original view with their boxes on the page.
final StreamProviderFamily<List<(Annotation, PageHighlight)>, (String, String)>
_highlightsProvider = StreamProvider.autoDispose
    .family<List<(Annotation, PageHighlight)>, (String, String)>((ref, key) {
      final (bookId, path) = key;
      final adapter = ref.watch(pdfAdapterProvider);
      return ref
          .watch(annotationRepositoryProvider)
          .watch(bookId, ReadingView.original)
          .asyncMap(
            (list) async => [
              for (final a in list)
                (
                  a,
                  PageHighlight(
                    id: a.id,
                    page: a.page,
                    argb: a.color.argb,
                    rects: await adapter.textRects(
                      path,
                      page: a.page,
                      start: a.start,
                      end: a.end,
                    ),
                  ),
                ),
            ],
          );
    });

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

  Future<void> _highlight(
    List<PdfSelection> selection, {
    bool note = false,
  }) async {
    final id = widget.bookId;
    if (id == null || selection.isEmpty) return;
    String? text;
    if (note) {
      text = await askForNote(context);
      if (text == null) return;
    }
    final repository = ref.read(annotationRepositoryProvider);
    for (final s in selection) {
      await repository.add(
        id,
        AnnotationDraft(
          view: ReadingView.original,
          page: s.page,
          start: s.start,
          end: s.end,
          quote: s.text.trim(),
          note: text == null || text.trim().isEmpty ? null : text.trim(),
        ),
      );
    }
  }

  void _goToPage(int page) => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ViewerScreen(
        path: widget.path,
        title: widget.title,
        bookId: widget.bookId,
        initialPage: page,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(_pdfInfoProvider(widget.path));
    final id = widget.bookId;
    final book = id == null ? null : ref.watch(bookProvider(id)).value;
    final highlights = id == null
        ? const <(Annotation, PageHighlight)>[]
        : ref.watch(_highlightsProvider((id, widget.path))).value ??
              const <(Annotation, PageHighlight)>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l10n.appTitle),
        actions: [
          if (id != null)
            IconButton(
              tooltip: l10n.highlights,
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () => showAnnotationList(context, [
                for (final (a, _) in highlights) a,
              ], onOpen: (a) => _goToPage(a.page)),
            ),
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
              highlights: [for (final (_, h) in highlights) h],
              selectionActions: id == null
                  ? const []
                  : [
                      SelectionAction(
                        label: l10n.highlight,
                        onSelected: _highlight,
                      ),
                      SelectionAction(
                        label: l10n.addNote,
                        onSelected: (s) => _highlight(s, note: true),
                      ),
                    ],
              onHighlightTap: (annotationId) {
                for (final (a, _) in highlights) {
                  if (a.id == annotationId) {
                    unawaited(showAnnotationSheet(context, ref, a));
                  }
                }
              },
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
