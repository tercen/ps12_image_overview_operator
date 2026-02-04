import 'dart:typed_data';
import '../../domain/models/image_metadata.dart';

/// Concrete implementation of ImageMetadata
class ImageMetadataImpl implements ImageMetadata {
  @override
  final String id;

  @override
  final String filename;

  @override
  final String barcode;

  @override
  final int well;

  @override
  final int field;

  @override
  final int cycle;

  @override
  final int exposureTime;  // T value: 5, 10, 25, 50, 100 ms

  @override
  final int? imageIndex;   // I value: sequential capture number

  @override
  final Uint8List? bytes;

  @override
  final String? imagePath;

  @override
  final String? dateTime;

  ImageMetadataImpl({
    required this.id,
    required this.filename,
    required this.barcode,
    required this.well,
    required this.field,
    required this.cycle,
    required this.exposureTime,
    this.imageIndex,
    this.bytes,
    this.imagePath,
    this.dateTime,
  });
}
