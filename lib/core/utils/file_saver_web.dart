// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

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

  // Wrap the bytes in a typed Uint8List so the browser receives the payload
  // as a real ArrayBufferView. Passing a plain List<int> serializes as a JS
  // Array of numbers, which Blob coerces into broken text content — the file
  // saves at roughly the right size but cannot be rendered as a PDF anywhere.
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  _lastPdfUrl = url;

  // No auto-download here: on iOS Safari clicking an anchor with `download`
  // ignores the attribute and instead navigates the current tab to the blob
  // URL, which kills the Flutter app before any follow-up dialog can render.
  // The caller shows an explicit "Open PDF" button that opens the URL on a
  // fresh user gesture (works on iOS Safari, iOS Chrome and desktop).
  return url;
}

void openPdfUrl(String url) {
  html.window.open(url, '_blank');
}
