class PickedImage {
  final String name;
  final int size;
  final String dataUrl;

  PickedImage({
    required this.name,
    required this.size,
    required this.dataUrl,
  });
}

Future<PickedImage?> pickImageFromDevice() async {
  throw UnimplementedError();
}

