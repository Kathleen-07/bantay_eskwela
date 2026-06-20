import 'dart:typed_data';

/// Result from file picker
class PhotoPickerResult {
  final Uint8List bytes;
  final String name;

  const PhotoPickerResult({required this.bytes, required this.name});
}

/// Stub implementation — overridden by web version
Future<PhotoPickerResult?> pickPhotoFromGallery({String accept = 'image/*'}) async {
  throw UnimplementedError(
      'pickPhotoFromGallery not implemented for this platform');
}
