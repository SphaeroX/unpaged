import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:paperflow/core/pdf/pdf_adapter.dart';
import 'package:paperflow/l10n/gen/app_localizations.dart';

/// Opens a PDF by path once and exposes its [PdfInfo].
final FutureProviderFamily<PdfInfo, String> _pdfInfoProvider = FutureProvider
    .autoDispose
    .family<PdfInfo, String>(
      (ref, path) => ref.watch(pdfAdapterProvider).inspect(path),
    );

/// Original page view of a single PDF.
class ViewerScreen extends ConsumerWidget {
  const new({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(_pdfInfoProvider(path));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: info.when(
        data: (_) => ref.read(pdfAdapterProvider).pageView(path),
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
