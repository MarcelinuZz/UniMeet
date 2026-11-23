import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'image_picker_stub.dart';

Future<PickedImage?> pickImageFromDevice() async {
  final completer = Completer<PickedImage?>();
  final uploadInput = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/jpg,image/webp'
    ..multiple = false
    ..style.display = 'none';

  web.document.body?.append(uploadInput);

  void cleanup() {
    uploadInput.remove();
  }

  uploadInput.addEventListener(
    'change',
    ((web.Event event) {
      final files = uploadInput.files;
      if (files == null || files.length == 0) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.item(0)!;
      final reader = web.FileReader();

      reader.addEventListener(
        'loadend',
        ((web.Event _) {
          cleanup();
          final result = reader.result;
          if (result != null && result.isA<JSString>()) {
            final jsStr = result as JSString;
            completer.complete(
              PickedImage(
                name: file.name,
                size: file.size,
                dataUrl: jsStr.toDart,
              ),
            );
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        }).toJS,
      );

      reader.addEventListener(
        'error',
        ((web.Event _) {
          cleanup();
          if (!completer.isCompleted) completer.complete(null);
        }).toJS,
      );

      reader.readAsDataURL(file);
    }).toJS,
  );

  uploadInput.addEventListener(
    'cancel',
    ((web.Event _) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );

  uploadInput.click();
  return completer.future;
}
