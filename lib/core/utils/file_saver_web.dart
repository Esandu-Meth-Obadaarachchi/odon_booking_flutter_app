// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> saveAndOpenPdf(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Use an anchor with the `download` attribute rather than window.open.
  // iOS Safari blocks window.open() as a popup when it runs after an async
  // gap (the PDF is generated with `await` before this is called), so the
  // invoice never opens. A programmatic anchor click triggers a normal
  // download instead, which iOS allows — the file lands in Files/Downloads.
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  // Revoke after a short delay so the download has time to start.
  Future.delayed(const Duration(seconds: 10), () => html.Url.revokeObjectUrl(url));
}
