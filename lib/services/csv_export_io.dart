import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportAndShareCsv({
  required String csvContent,
  required String fileName,
  required String subject,
  required String text,
}) async {
  final Directory tempDir = await getTemporaryDirectory();
  final String filePath = '${tempDir.path}/$fileName';
  final File file = File(filePath);
  await file.writeAsString(csvContent);

  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(filePath)],
      subject: subject,
      text: text,
    ),
  );
}

