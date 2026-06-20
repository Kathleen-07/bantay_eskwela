import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Cloudinary service for uploading student photos and consent files.
/// Security: Uses unsigned upload preset — no API secret exposed.
class CloudinaryService {
  static const String _cloudName = 'dknoxu9dl';
  static const String _uploadPreset = 'bantayeskwela_students';

  static String get _imageUploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // 'auto' endpoint handles any file type (images AND PDFs/raw files)
  static String get _autoUploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  /// Upload image bytes to Cloudinary using multipart upload.
  /// Returns the secure URL of the uploaded image.
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    // Validate file size (max 5MB for photos)
    if (imageBytes.isEmpty) throw Exception('Image is empty');
    if (imageBytes.length > 5 * 1024 * 1024) {
      throw Exception('Image too large. Maximum size is 5MB.');
    }

    // Validate file extension
    final extension = fileName.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid image type. Allowed: JPG, PNG, WEBP');
    }

    return _upload(
      url: _imageUploadUrl,
      bytes: imageBytes,
      fileName: fileName,
    );
  }

  /// Upload any file (PDF, PNG, JPG) for consent forms.
  /// Returns the secure URL of the uploaded file.
  static Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (fileBytes.isEmpty) throw Exception('File is empty');
    if (fileBytes.length > 10 * 1024 * 1024) {
      throw Exception('File too large. Maximum size is 10MB.');
    }

    final extension = fileName.split('.').last.toLowerCase();
    final allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Invalid file type. Allowed: PDF, PNG, JPG');
    }

    return _upload(
      url: _autoUploadUrl,
      bytes: fileBytes,
      fileName: fileName,
    );
  }

  /// Shared multipart upload logic
  static Future<String> _upload({
    required String url,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

      request.fields['upload_preset'] = _uploadPreset;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }

      final responseData = json.decode(response.body);
      final secureUrl = responseData['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Upload succeeded but no URL returned');
      }

      return secureUrl;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to upload file. Please try again.');
    }
  }
}
