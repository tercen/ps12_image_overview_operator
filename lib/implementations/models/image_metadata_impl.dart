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
  final int exposureTime;

  @override
  final Uint8List? bytes;

  @override
  final String? imagePath;

  @override
  final int? temperature;

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
    this.bytes,
    this.imagePath,
    this.temperature,
    this.dateTime,
  });
}
