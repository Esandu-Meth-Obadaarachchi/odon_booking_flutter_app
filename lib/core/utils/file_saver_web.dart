// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> saveAndOpenPdf(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke after a short delay to allow the tab to load
  Future.delayed(const Duration(seconds: 10), () => html.Url.revokeObjectUrl(url));
}
