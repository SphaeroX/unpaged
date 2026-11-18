import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/core/files/book_file_store.dart';
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

/// eBook mode: the reflowed text with zoomable crops for non-text regions.
class ReaderScreen extends ConsumerWidget {
  const new({required this.bookId, required this.title, super.key});

  final String bookId;
  final String title;

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
                ),
              ),
            ),
          ),
        ],
      ),
      body: doc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Unavailable(onPrepare: () => _prepareAgain(ref)),
        data: (doc) => doc == null
            ? _Unavailable(onPrepare: () => _prepareAgain(ref))
            : _BlockList(bookId: bookId, blocks: doc.blocks),
      ),
    );
  }
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

class _BlockList extends ConsumerWidget {
  const new({required this.bookId, required this.blocks});

  final String bookId;
  final List<ReflowBlock> blocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(reflowStoreProvider);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: blocks.length,
      itemBuilder: (context, i) {
        final block = blocks[i];
        if (block.type.isRegion) {
          return _Crop(
            key: ValueKey('crop-${block.id}'),
            file: store.cropFile(bookId, block.id),
          );
        }
        return _TextBlock(block: block);
      },
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
