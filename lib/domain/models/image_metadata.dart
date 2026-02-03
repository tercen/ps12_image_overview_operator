import 'dart:typed_data';

/// Abstract interface for image metadata
abstract class ImageMetadata {
  String get id;
  String get filename;
  String get barcode;
  int get well;
  int get field;
  int get cycle;
  int get exposureTime;
  Uint8List? get bytes;
  String? get imagePath;
  int? get temperature;
  String? get dateTime;
}
