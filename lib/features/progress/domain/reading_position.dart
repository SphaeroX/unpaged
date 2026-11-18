import 'package:flutter/foundation.dart';
import 'package:reflow_engine/reflow_engine.dart';

enum ReadingView { original, ebook }

/// Where reading stopped in one view of a book.
@immutable
class ReadingPosition {
  const new({
    required this.view,
    required this.page,
    required this.progress,
    this.blockId,
  });

  final ReadingView view;

  /// 1-based page (original) or source page of [blockId] (eBook).
  final int page;

  /// eBook only: the block at the top of the screen.
  final String? blockId;

  /// 0..1, shown in the library.
  final double progress;
}

/// Index of the first block of [page]; a page without blocks maps to the
/// next block after it, a page after the end to the last block.
int blockIndexForPage(ReflowDocument doc, int page) {
  if (doc.blocks.isEmpty) return 0;
  final index = doc.blocks.indexWhere((b) => b.page >= page);
  return index == -1 ? doc.blocks.length - 1 : index;
}

/// Source page of the block at [index].
int pageOfBlock(ReflowDocument doc, int index) => doc.blocks.isEmpty
    ? 1
    : doc.blocks[index.clamp(0, doc.blocks.length - 1)].page;

/// The stored block if it still exists, otherwise the stored page (block
/// ids can change when the engine recomputes the document).
int resolveBlockIndex(
  ReflowDocument doc, {
  required String? blockId,
  required int page,
}) {
  final byId = doc.blocks.indexWhere((b) => b.id == blockId);
  return byId != -1 ? byId : blockIndexForPage(doc, page);
}

double originalProgress({required int page, required int pageCount}) =>
    pageCount <= 0 ? 0 : (page / pageCount).clamp(0, 1).toDouble();

double ebookProgress({required int index, required int count}) =>
    count <= 0 ? 0 : ((index + 1) / count).clamp(0, 1).toDouble();
