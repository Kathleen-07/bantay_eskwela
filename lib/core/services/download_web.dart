// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation — triggers browser download
Future<void> downloadFileWeb({
  required Uint8List bytes,
  required String fileName,
}) async {
  // Sanitize filename to prevent path traversal
  final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');

  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(
    href: 'data:image/png;base64,$base64Data',
  )
    ..setAttribute('download', safeName)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
