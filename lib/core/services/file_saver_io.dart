import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Android/iOS: write [bytes] to a temp file, then open the share sheet so the
/// user can save it to Files, Drive, email, etc.
Future<void> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path, mimeType: mimeType)],
      subject: safeName);
}
