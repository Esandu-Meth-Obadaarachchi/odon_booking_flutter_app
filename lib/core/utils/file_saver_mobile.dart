import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> saveAndOpenPdf(List<int> bytes, String fileName) async {
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(bytes);

  // Also copy to external storage (Downloads) on Android
  try {
    final downloads = await getExternalStorageDirectory();
    if (downloads != null) {
      final downloadFile = File('${downloads.path}/$fileName');
      await downloadFile.writeAsBytes(bytes);
    }
  } catch (_) {}

  await OpenFile.open(file.path);
}
