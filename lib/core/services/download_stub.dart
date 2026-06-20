import 'dart:typed_data';

/// Stub implementation for non-web platforms
Future<void> downloadFileWeb({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnimplementedError('Web download not available on this platform');
}
