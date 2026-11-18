import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/features/annotations/data/annotation_repository.dart';
import 'package:paperflow/features/annotations/domain/annotation.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

/// Asks for a note; returns `null` if cancelled.
Future<String?> askForNote(BuildContext context, {String initial = ''}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.note),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        minLines: 1,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

/// Shows a highlight: quote, editable note, colour, delete.
Future<void> showAnnotationSheet(
  BuildContext context,
  WidgetRef ref,
  Annotation annotation,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _AnnotationSheet(annotation: annotation, parentRef: ref),
);

class _AnnotationSheet extends StatefulWidget {
  const new({required this.annotation, required this.parentRef});

  final Annotation annotation;
  final WidgetRef parentRef;

  @override
  State<_AnnotationSheet> createState() => _AnnotationSheetState();
}

class _AnnotationSheetState extends State<_AnnotationSheet> {
  late final _note = TextEditingController(text: widget.annotation.note ?? '');
  late HighlightColor _color = widget.annotation.color;

  AnnotationRepository get _repository =>
      widget.parentRef.read(annotationRepositoryProvider);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _note.text.trim();
    await _repository.update(
      widget.annotation.id,
      note: text.isEmpty ? null : text,
      clearNote: text.isEmpty,
      color: _color,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await _repository.delete(widget.annotation.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.annotation.quote,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in HighlightColor.values)
                ChoiceChip(
                  label: const SizedBox(width: 16, height: 16),
                  avatar: CircleAvatar(backgroundColor: Color(c.argb)),
                  selected: c == _color,
                  onSelected: (_) => setState(() => _color = c),
                ),
            ],
          ),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l10n.note),
            maxLines: 4,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: _delete, child: Text(l10n.deleteBook)),
              const Spacer(),
              FilledButton(onPressed: _save, child: Text(l10n.save)),
            ],
          ),
        ],
      ),
    );
  }
}

/// List of a book's highlights; tapping one calls [onOpen].
Future<void> showAnnotationList(
  BuildContext context,
  List<Annotation> annotations, {
  required void Function(Annotation) onOpen,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    if (annotations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.noHighlights),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final a in annotations)
          ListTile(
            leading: CircleAvatar(
              radius: 8,
              backgroundColor: Color(a.color.argb),
            ),
            title: Text(a.quote, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [l10n.pageLabel(a.page), ?a.note].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).pop();
              onOpen(a);
            },
          ),
      ],
    );
  },
);
