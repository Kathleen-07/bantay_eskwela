// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:bantay_eskwela/core/services/photo_picker_stub.dart';

/// Web implementation using dart:html — guaranteed to work on all browsers.
/// The [accept] parameter controls which file types the picker shows
/// (e.g. 'image/*' for photos, '.pdf,image/*' for consent forms).
Future<PhotoPickerResult?> pickPhotoFromGallery(
    {String accept = 'image/*'}) async {
  final completer = Completer<PhotoPickerResult?>();

  final input = html.FileUploadInputElement()..accept = accept;
  input.click();

  bool handled = false;

  input.onChange.listen((event) {
    if (handled) return;
    handled = true;

    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((event) {
      try {
        final result = reader.result;
        Uint8List bytes;

        if (result is Uint8List) {
          bytes = result;
        } else if (result is ByteBuffer) {
          bytes = result.asUint8List();
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else {
          completer.complete(null);
          return;
        }

        completer.complete(PhotoPickerResult(
          bytes: bytes,
          name: file.name,
        ));
      } catch (e) {
        completer.complete(null);
      }
    });

    reader.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
  });

  return completer.future;
}
