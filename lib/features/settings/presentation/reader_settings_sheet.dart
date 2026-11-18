import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/features/settings/domain/reader_settings.dart';
import 'package:paperflow/features/settings/presentation/reader_settings_controller.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

/// Bottom sheet with font, size, line spacing and theme; changes show
/// immediately in the reader behind it.
class ReaderSettingsSheet extends ConsumerWidget {
  const new({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ReaderSettingsSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(readerSettingsProvider).value ?? ReaderSettings.defaults;
    void update(ReaderSettings Function(ReaderSettings) change) =>
        ref.read(readerSettingsProvider.notifier).change(change);

    Widget stepper({
      required String label,
      required String value,
      required String lessTooltip,
      required String moreTooltip,
      required VoidCallback onLess,
      required VoidCallback onMore,
    }) => Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: lessTooltip,
          icon: const Icon(Icons.remove),
          onPressed: onLess,
        ),
        SizedBox(width: 48, child: Text(value, textAlign: TextAlign.center)),
        IconButton(
          tooltip: moreTooltip,
          icon: const Icon(Icons.add),
          onPressed: onMore,
        ),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.font),
            const SizedBox(height: 8),
            SegmentedButton<ReaderFont>(
              segments: [
                ButtonSegment(
                  value: ReaderFont.literata,
                  label: Text(l10n.fontSerif),
                ),
                ButtonSegment(
                  value: ReaderFont.atkinson,
                  label: Text(l10n.fontSans),
                ),
                ButtonSegment(
                  value: ReaderFont.system,
                  label: Text(l10n.fontSystem),
                ),
              ],
              selected: {settings.font},
              onSelectionChanged: (s) =>
                  update((x) => x.copyWith(font: s.first)),
            ),
            const SizedBox(height: 8),
            stepper(
              label: l10n.textSize,
              value: settings.fontSize.round().toString(),
              lessTooltip: l10n.smallerText,
              moreTooltip: l10n.largerText,
              onLess: () => update((x) => x.smallerFont()),
              onMore: () => update((x) => x.biggerFont()),
            ),
            stepper(
              label: l10n.lineSpacing,
              value: settings.lineHeight.toStringAsFixed(1),
              lessTooltip: l10n.tighterLines,
              moreTooltip: l10n.widerLines,
              onLess: () => update((x) => x.tighterLines()),
              onMore: () => update((x) => x.widerLines()),
            ),
            const SizedBox(height: 8),
            Text(l10n.theme),
            const SizedBox(height: 8),
            SegmentedButton<ReaderTheme>(
              segments: [
                ButtonSegment(
                  value: ReaderTheme.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ReaderTheme.dark,
                  label: Text(l10n.themeDark),
                ),
                ButtonSegment(
                  value: ReaderTheme.sepia,
                  label: Text(l10n.themeSepia),
                ),
              ],
              selected: {settings.theme},
              onSelectionChanged: (s) =>
                  update((x) => x.copyWith(theme: s.first)),
            ),
          ],
        ),
      ),
    );
  }
}
