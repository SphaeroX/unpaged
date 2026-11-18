import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperflow/core/files/book_file_store.dart';
import 'package:paperflow/core/files/pdf_picker.dart';
import 'package:paperflow/core/files/pdf_source.dart';
import 'package:pdfrx/pdfrx.dart';

import '../app/helpers/test_app.dart';

/// tests/fixtures/three_pages.pdf, inlined so it needs no app asset.
const _threePagesPdf =
    'JVBERi0xLjMKJenr8b8KMSAwIG9iago8PAovQ291bnQgMwovS2lkcyBbMyAwIFIKNSAwIFIKNyAwIFJdCi9NZWRpYUJveCBbMCAwIDU5NS4yOCA4NDEuODldCi9UeXBlIC9QYWdlcwo+PgplbmRvYmoKMiAwIG9iago8PAovT3BlbkFjdGlvbiBbMyAwIFIgL0ZpdEggbnVsbF0KL1BhZ2VMYXlvdXQgL09uZUNvbHVtbgovUGFnZXMgMSAwIFIKL1R5cGUgL0NhdGFsb2cKPj4KZW5kb2JqCjMgMCBvYmoKPDwKL0NvbnRlbnRzIDQgMCBSCi9QYXJlbnQgMSAwIFIKL1Jlc291cmNlcyAxMCAwIFIKL1R5cGUgL1BhZ2UKPj4KZW5kb2JqCjQgMCBvYmoKPDwKL0ZpbHRlciAvRmxhdGVEZWNvZGUKL0xlbmd0aCA4Mgo+PgpzdHJlYW0KeJwzUvDiMtAzNVco53IKUdB3M1QwNNIzMFAISVNwDQEJGRvqGVooWBgY61maKISkKGh4pObk5CsUJBakFqXl5JcDWempCoaaCiFZIB0A3GIT/wplbmRzdHJlYW0KZW5kb2JqCjUgMCBvYmoKPDwKL0NvbnRlbnRzIDYgMCBSCi9QYXJlbnQgMSAwIFIKL1Jlc291cmNlcyAxMSAwIFIKL1R5cGUgL1BhZ2UKPj4KZW5kb2JqCjYgMCBvYmoKPDwKL0ZpbHRlciAvRmxhdGVEZWNvZGUKL0xlbmd0aCA4Mgo+PgpzdHJlYW0KeJwzUvDiMtAzNVco53IKUdB3M1QwNNIzMFAISVNwDQEJGRvqGVooWBgY61maKISkKGh4pObk5CsUJBakFqXl5JcDWempCkaaCiFZIB0A3GsUAAplbmRzdHJlYW0KZW5kb2JqCjcgMCBvYmoKPDwKL0NvbnRlbnRzIDggMCBSCi9QYXJlbnQgMSAwIFIKL1Jlc291cmNlcyAxMiAwIFIKL1R5cGUgL1BhZ2UKPj4KZW5kb2JqCjggMCBvYmoKPDwKL0ZpbHRlciAvRmxhdGVEZWNvZGUKL0xlbmd0aCA4Mgo+PgpzdHJlYW0KeJwzUvDiMtAzNVco53IKUdB3M1QwNNIzMFAISVNwDQEJGRvqGVooWBgY61maKISkKGh4pObk5CsUJBakFqXl5JcDWempCsaaCiFZIB0A3HQUAQplbmRzdHJlYW0KZW5kb2JqCjkgMCBvYmoKPDwKL0Jhc2VGb250IC9IZWx2ZXRpY2EKL0VuY29kaW5nIC9XaW5BbnNpRW5jb2RpbmcKL1N1YnR5cGUgL1R5cGUxCi9UeXBlIC9Gb250Cj4+CmVuZG9iagoxMCAwIG9iago8PAovRm9udCA8PC9GMSA5IDAgUj4+Ci9Qcm9jU2V0IFsvUERGIC9UZXh0IC9JbWFnZUIgL0ltYWdlQyAvSW1hZ2VJXQo+PgplbmRvYmoKMTEgMCBvYmoKPDwKL0ZvbnQgPDwvRjEgOSAwIFI+PgovUHJvY1NldCBbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0KPj4KZW5kb2JqCjEyIDAgb2JqCjw8Ci9Gb250IDw8L0YxIDkgMCBSPj4KL1Byb2NTZXQgWy9QREYgL1RleHQgL0ltYWdlQiAvSW1hZ2VDIC9JbWFnZUldCj4+CmVuZG9iagoxMyAwIG9iago8PAovQ3JlYXRpb25EYXRlIChEOjIwMjYxMTE4MDIzNDM3WikKPj4KZW5kb2JqCnhyZWYKMCAxNAowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMTUgMDAwMDAgbiAKMDAwMDAwMDExNCAwMDAwMCBuIAowMDAwMDAwMjE3IDAwMDAwIG4gCjAwMDAwMDAyOTggMDAwMDAgbiAKMDAwMDAwMDQ1MSAwMDAwMCBuIAowMDAwMDAwNTMyIDAwMDAwIG4gCjAwMDAwMDA2ODUgMDAwMDAgbiAKMDAwMDAwMDc2NiAwMDAwMCBuIAowMDAwMDAwOTE5IDAwMDAwIG4gCjAwMDAwMDEwMTYgMDAwMDAgbiAKMDAwMDAwMTEwNCAwMDAwMCBuIAowMDAwMDAxMTkyIDAwMDAwIG4gCjAwMDAwMDEyODAgMDAwMDAgbiAKdHJhaWxlcgo8PAovU2l6ZSAxNAovUm9vdCAyIDAgUgovSW5mbyAxMyAwIFIKL0lEIFs8MTFCOTgxQjcwRUI2QjA5MUZDMjVFRkI4MDU4MUFERjc+PDExQjk4MUI3MEVCNkIwOTFGQzI1RUZCODA1ODFBREY3Pl0KPj4Kc3RhcnR4cmVmCjEzMzYKJSVFT0YK';

class _FixedPicker implements PdfPicker {
  new(this.path);

  final String path;

  @override
  Future<PdfSource?> pickPdf() async => FilePdfSource(path);
}

// Since Task 05: import into the library → open → delete (approved change
// of the Task 01 flow, see Roadmap/README.md).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('imports a PDF, shows its pages and deletes it again', (
    tester,
  ) async {
    final tmp = Directory.systemTemp.createTempSync('paperflow_it');
    final file = File('${tmp.path}/three_pages.pdf');
    await file.writeAsBytes(base64Decode(_threePagesPdf));

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          pdfPickerProvider.overrideWithValue(_FixedPicker(file.path)),
          bookFileStoreProvider.overrideWithValue(BookFileStore(tmp)),
        ],
      ),
    );
    await tester.tap(find.text('Open PDF'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('This PDF could not be opened.'), findsNothing);
    expect(find.byType(PdfViewer), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('three pages'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('three pages'), findsNothing);
  });
}
