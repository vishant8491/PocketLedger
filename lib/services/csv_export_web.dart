import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

Future<void> exportAndShareCsv({
  required String csvContent,
  required String fileName,
  required String subject,
  required String text,
}) async {
  try {
    final List<int> bytes = utf8.encode(csvContent);
    final XFile xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      name: fileName,
    );

    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[xFile],
        subject: subject,
        text: text,
        downloadFallbackEnabled: true,
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      _triggerBrowserDownload(csvContent, fileName);
    }
  } catch (_) {
    _triggerBrowserDownload(csvContent, fileName);
  }
}

void _triggerBrowserDownload(String content, String fileName) {
  final web.Blob blob = web.Blob(
    <JSAny>[content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

