import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/files/pdf_picker.dart';
import 'package:paperflow/features/viewer/presentation/viewer_screen.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(pdfPickerProvider).pickPdf();
    if (path == null || !context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ViewerScreen(path: path)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => _open(context, ref),
          icon: const Icon(Icons.file_open),
          label: Text(l10n.openPdf),
        ),
      ),
    );
  }
}
