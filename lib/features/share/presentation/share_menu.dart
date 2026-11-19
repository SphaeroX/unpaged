import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/platform/pdf_share_channel.dart';
import 'package:unpaged/core/widgets/app_bar_actions.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

/// Entries of the ⋮ menu that share or print the original PDF at [path];
/// the shared file and the print job are named after the book [title].
List<MenuEntry> pdfShareEntries(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String title,
}) {
  final l10n = AppLocalizations.of(context);
  final channel = ref.read(pdfShareChannelProvider);
  final name = PdfShareChannel.fileNameFor(title);

  Future<void> run(Future<bool> Function() action) async {
    if (await action() || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).shareUnavailable)),
    );
  }

  return [
    MenuEntry(
      icon: Icons.share_outlined,
      label: l10n.sharePdf,
      onSelected: () => run(() => channel.share(path, name: name)),
    ),
    MenuEntry(
      icon: Icons.print_outlined,
      label: l10n.printPdf,
      onSelected: () => run(() => channel.print(path, name: name)),
    ),
  ];
}
