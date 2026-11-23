import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:windows_file_picker/windows_file_picker.dart';
import 'image_picker_stub.dart';

Future<PickedImage?> pickImageFromDevice() async {
  try {
    if (io.Platform.isWindows && FilePickerPlatform.instance is! FilePickerWindows) {
      FilePickerWindows.registerWith();
    }
  } catch (_) {}

  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
  );

  if (files.isEmpty) return null;
  final file = files.first;
  final bytes = await file.readAsBytes();
  final size = await file.length() ?? bytes.length;
  final ext = (file.extension ?? 'jpeg').toLowerCase();
  final mime = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
  final base64String = base64Encode(bytes);
  final dataUrl = 'data:$mime;base64,$base64String';

  return PickedImage(
    name: file.name,
    size: size,
    dataUrl: dataUrl,
  );
}

