import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/features/progress/data/reading_position_repository.dart';
import 'package:paperflow/features/progress/domain/reading_position.dart';
import 'package:paperflow/features/reflow/data/reflow_store.dart';
import 'package:paperflow/features/reflow/domain/reflow_scheduler.dart';
import 'package:paperflow/features/settings/domain/reader_settings.dart';
import 'package:paperflow/features/settings/presentation/reader_settings_controller.dart';
import 'package:paperflow/features/settings/presentation/reader_settings_sheet.dart';
import 'package:paperflow/features/viewer/presentation/viewer_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';
import 'package:reflow_engine/reflow_engine.dart';

/// The stored reflow document of a book; `null` if missing or damaged.
final FutureProviderFamily<ReflowDocument?, String> reflowDocumentProvider =
    FutureProvider.autoDispose.family<ReflowDocument?, String>(
      (ref, bookId) => ref.watch(reflowStoreProvider).readDocument(bookId),
    );

/// The saved eBook position of a book, if any.
final FutureProviderFamily<ReadingPosition?, String> _savedEbookPosition =
    FutureProvider.autoDispose.family<ReadingPosition?, String>(
      (ref, bookId) => ref
          .watch(readingPositionRepositoryProvider)
          .load(bookId, ReadingView.ebook),
    );

/// eBook mode: the reflowed text with zoomable crops for non-text regions.
class ReaderScreen extends ConsumerWidget {
  const new({
    required this.bookId,
    required this.title,
    this.initialPage,
    super.key,
  });

  final String bookId;
  final String title;

  /// Start at the first block of this page (switching from the original);
  /// `null` resumes at the saved position.
  final int? initialPage;

  Future<void> _prepareAgain(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
      const BooksCompanion(
        reflowStatus: Value(ReflowStatus.pending),
        reflowProgress: Value(0),
      ),
    );
    ref.read(reflowSchedulerProvider).enqueue(bookId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final doc = ref.watch(reflowDocumentProvider(bookId));
    final saved = initialPage == null
        ? ref.watch(_savedEbookPosition(bookId))
        : const AsyncData<ReadingPosition?>(null);
    final current = _CurrentBlock();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.readingSettings,
            icon: const Icon(Icons.text_fields),
            onPressed: () => ReaderSettingsSheet.show(context),
          ),
          IconButton(
            tooltip: l10n.switchToOriginal,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => ViewerScreen(
                  path: ref.read(bookFileStoreProvider).fileFor(bookId).path,
                  title: title,
                  bookId: bookId,
                  initialPage: current.page ?? initialPage ?? 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: switch ((doc, saved)) {
        (AsyncData(value: final doc?), AsyncData(value: final position)) =>
          _BlockList(
            bookId: bookId,
            doc: doc,
            current: current,
            initialIndex: initialPage != null
                ? blockIndexForPage(doc, initialPage!)
                : position == null
                ? 0
                : resolveBlockIndex(
                    doc,
                    blockId: position.blockId,
                    page: position.page,
                  ),
          ),
        (AsyncData(value: null), _) ||
        (AsyncError(), _) => _Unavailable(onPrepare: () => _prepareAgain(ref)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The block currently at the top of the reader (shared with the app bar
/// action that switches to the original view).
class _CurrentBlock {
  int? page;
}

class _Unavailable extends StatelessWidget {
  const new({required this.onPrepare});

  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.readerUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPrepare, child: Text(l10n.prepareAgain)),
          ],
        ),
      ),
    );
  }
}

class _BlockList extends ConsumerStatefulWidget {
  const new({
    required this.bookId,
    required this.doc,
    required this.current,
    required this.initialIndex,
  });

  final String bookId;
  final ReflowDocument doc;
  final _CurrentBlock current;
  final int initialIndex;

  @override
  ConsumerState<_BlockList> createState() => _BlockListState();
}

class _BlockListState extends ConsumerState<_BlockList> {
  final _centerKey = UniqueKey();
  final GlobalKey<State<StatefulWidget>> _viewportKey = GlobalKey();
  final _itemKeys = <int, GlobalKey>{};

  List<ReflowBlock> get _blocks => widget.doc.blocks;

  @override
  void initState() {
    super.initState();
    widget.current.page = pageOfBlock(widget.doc, widget.initialIndex);
  }

  /// After the next layout, saves the block at the top of the viewport.
  bool _onScrollEnd(ScrollEndNotification _) {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _saveTopBlock())
      ..scheduleFrame();
    return false;
  }

  void _saveTopBlock() {
    if (!mounted) return;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    int? best;
    var bestDistance = double.infinity;
    for (final MapEntry(key: index, value: key) in _itemKeys.entries) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      final bottom = y + box.size.height;
      if (bottom <= top) continue;
      final distance = (y - top).abs();
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
    }
    if (best != null) _save(best);
  }

  void _save(int index) {
    final block = _blocks[index];
    widget.current.page = block.page;
    unawaited(
      ref
          .read(readingPositionRepositoryProvider)
          .save(
            widget.bookId,
            ReadingPosition(
              view: ReadingView.ebook,
              page: block.page,
              blockId: block.id,
              progress: ebookProgress(index: index, count: _blocks.length),
            ),
          ),
    );
  }

  Widget _item(int index) {
    final block = _blocks[index];
    final key = _itemKeys.putIfAbsent(index, GlobalKey.new);
    final store = ref.read(reflowStoreProvider);
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: block.type.isRegion
          ? _Crop(
              key: ValueKey('crop-${block.id}'),
              file: store.cropFile(widget.bookId, block.id),
            )
          : _TextBlock(block: block),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.initialIndex.clamp(0, _blocks.length);
    // Two slivers around a centre: the list starts at [start] without
    // measuring the (variable) heights of the blocks before it.
    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: CustomScrollView(
        key: _viewportKey,
        center: _centerKey,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _item(start - 1 - i),
              childCount: start,
            ),
          ),
          SliverPadding(
            key: _centerKey,
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _item(start + i),
                childCount: _blocks.length - start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends ConsumerWidget {
  const new({required this.block});

  final ReflowBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(readerSettingsProvider).value ?? ReaderSettings.defaults;
    final body = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontFamily: settings.font.family,
      fontSize: settings.fontSize,
      height: settings.lineHeight,
    );
    final size = settings.fontSize;
    final (style, padding) = switch (block.type) {
      BlockType.heading => (
        body.copyWith(
          fontSize: switch (block.level ?? 2) {
            1 => size * 1.45,
            2 => size * 1.25,
            _ => size * 1.1,
          },
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        EdgeInsets.only(top: size, bottom: size * 0.4),
      ),
      BlockType.listItem => (
        body,
        EdgeInsets.only(left: size, bottom: size * 0.35),
      ),
      BlockType.caption => (
        body.copyWith(fontSize: size * 0.85, fontStyle: FontStyle.italic),
        EdgeInsets.only(bottom: size * 0.9),
      ),
      _ => (body, EdgeInsets.only(bottom: size * 0.7)),
    };
    return Padding(
      padding: padding,
      child: Text(block.text, style: style),
    );
  }
}

class _Crop extends StatelessWidget {
  const new({required this.file, super.key});

  final File file;

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox(
        height: 80,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => _ZoomScreen(file: file)),
        ),
        child: image,
      ),
    );
  }
}

/// Full-screen crop with pinch zoom and double-tap to toggle zoom.
class _ZoomScreen extends StatefulWidget {
  const new({required this.file});

  final File file;

  @override
  State<_ZoomScreen> createState() => _ZoomScreenState();
}

class _ZoomScreenState extends State<_ZoomScreen> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
      return;
    }
    final p = _doubleTap?.localPosition ?? Offset.zero;
    _controller.value = Matrix4.identity()
      ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
      ..scaleByDouble(2.5, 2.5, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GestureDetector(
        onDoubleTapDown: (d) => _doubleTap = d,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _controller,
          maxScale: 8,
          child: Center(child: Image.file(widget.file)),
        ),
      ),
    );
  }
}
