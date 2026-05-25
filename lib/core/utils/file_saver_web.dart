// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Holds the blob URL of the most recently generated PDF so a follow-up user
// gesture (e.g. a button tap in a dialog) can open it. iOS Safari blocks
// `window.open()` calls that happen after an async gap, so we rely on the
// caller to open the URL from a fresh tap.
String? _lastPdfUrl;

Future<String?> saveAndOpenPdf(List<int> bytes, String fileName) async {
  // Revoke previous URL so we don't accumulate blobs across invoices.
  if (_lastPdfUrl != null) {
    try {
      html.Url.revokeObjectUrl(_lastPdfUrl!);
    } catch (_) {}
  }

  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  _lastPdfUrl = url;

  // Trigger a normal download for desktop browsers. On iOS Safari this is a
  // no-op (Safari ignores the `download` attribute on cross-origin / blob
  // URLs), which is why we also return the URL so the UI can offer an
  // explicit "Open PDF" button on a fresh user gesture.
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  return url;
}

void openPdfUrl(String url) {
  html.window.open(url, '_blank');
}
