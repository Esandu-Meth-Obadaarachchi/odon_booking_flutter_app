// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

String? _lastPdfUrl;
List<int>? _lastPdfBytes;
String? _lastPdfFileName;

Future<String?> saveAndOpenPdf(List<int> bytes, String fileName) async {
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
  _lastPdfBytes = bytes;
  _lastPdfFileName = fileName;

  return url;
}

void openPdfUrl(String url) {
  html.window.open(url, '_blank');
}

// Tries the Web Share API with a real File object. This is what iOS Safari
// needs to share to WhatsApp/Mail with the correct filename and *without*
// leaking the page URL as a caption (which is what happens when the user
// shares a blob: URL from inside Safari's PDF viewer).
//
// Returns true if the share sheet was invoked, false if the browser does not
// support sharing files (in which case the caller should fall back to the
// Open PDF flow).
Future<bool> sharePdfLast() async {
  final bytes = _lastPdfBytes;
  final fileName = _lastPdfFileName;
  if (bytes == null || fileName == null) return false;

  try {
    final blob = html.Blob(
      [Uint8List.fromList(bytes)],
      'application/pdf',
    );
    final file = html.File(
      [blob],
      fileName,
      {'type': 'application/pdf'},
    );
    await html.window.navigator.share({
      'files': [file],
      'title': fileName,
    });
    return true;
  } catch (_) {
    return false;
  }
}
