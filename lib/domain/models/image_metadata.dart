import 'dart:typed_data';

/// Abstract interface for image metadata
abstract class ImageMetadata {
  String get id;
  String get filename;
  String get barcode;
  int get well;
  int get field;
  int get cycle;
  int get exposureTime;      // T value: 5, 10, 25, 50, 100 ms
  int? get imageIndex;       // I value: sequential capture number
  Uint8List? get bytes;
  String? get imagePath;
  String? get dateTime;
}
