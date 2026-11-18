import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/platform/pdf_share_channel.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

enum _ShareAction { share, print }

/// App-bar menu that shares or prints the original PDF at [path].
class PdfShareMenu extends ConsumerWidget {
  const new({required this.path, required this.title, super.key});

  final String path;

  /// Book title; the shared file and the print job are named after it.
  final String title;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _ShareAction action,
  ) async {
    final channel = ref.read(pdfShareChannelProvider);
    final name = PdfShareChannel.fileNameFor(title);
    final ok = switch (action) {
      _ShareAction.share => await channel.share(path, name: name),
      _ShareAction.print => await channel.print(path, name: name),
    };
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).shareUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_ShareAction>(
      tooltip: l10n.shareMenu,
      icon: const Icon(Icons.share_outlined),
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ShareAction.share,
          child: ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.sharePdf),
          ),
        ),
        PopupMenuItem(
          value: _ShareAction.print,
          child: ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(l10n.printPdf),
          ),
        ),
      ],
    );
  }
}
