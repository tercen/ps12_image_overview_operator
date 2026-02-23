import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';
import '../../domain/models/image_metadata.dart';
import '../../utils/pamgene_filename_parser.dart';
import '../models/image_metadata_impl.dart';

/// Mock implementation of ImageService using pre-converted PNG assets
class MockImageService implements ImageService {
  final Map<String, ImageMetadata> _cache = {};
  final Map<String, Uint8List> _bytesCache = {};

  MockImageService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock data for QC grid demonstration
    // 3 barcodes × 4 wells = 12 images
    // All at cycle P94, exposure T100 (100ms), field F1
    //
    // Filename format: {barcode}_W{well}_F{field}_T{exposureTime}_P{cycle}_I{imageIndex}_A{array}
    // - T = Exposure Time in ms (5, 10, 25, 50, 100)
    // - P = Pump Cycle number
    // - I = Image Index (sequential capture number)

    final mockImages = [
      // Barcode 641024305
      '641024305_W1_F1_T100_P94_I473_A30.png',
      '641024305_W2_F1_T100_P94_I478_A29.png',
      '641024305_W3_F1_T100_P94_I483_A29.png',
      '641024305_W4_F1_T100_P94_I488_A29.png',

      // Barcode 641024309
      '641024309_W1_F1_T100_P94_I493_A29.png',
      '641024309_W2_F1_T100_P94_I498_A29.png',
      '641024309_W3_F1_T100_P94_I503_A29.png',
      '641024309_W4_F1_T100_P94_I508_A29.png',

      // Barcode 641024313
      '641024313_W1_F1_T100_P94_I513_A29.png',
      '641024313_W2_F1_T100_P94_I518_A30.png',
      '641024313_W3_F1_T100_P94_I523_A30.png',
      '641024313_W4_F1_T100_P94_I528_A30.png',
    ];

    for (final filename in mockImages) {
      final parsed = PamGeneFilenameParser.parse(filename);
      if (parsed != null) {
        _cache[filename] = ImageMetadataImpl(
          id: filename,
          filename: filename,
          imagePath: 'assets/$filename',
          barcode: parsed['barcode'],
          well: parsed['well'],
          field: parsed['field'],
          cycle: parsed['pumpCycle'],
          exposureTime: parsed['exposureTime'],  // T value: 100ms
          imageIndex: parsed['imageIndex'],       // I value
        );
      }
    }
  }

  @override
  Future<ImageCollection> loadImages({void Function(String)? onStatus}) async {
    // Simulate realistic network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return ImageCollection(images: _cache.values.toList());
  }

  @override
  Future<ImageMetadata> getImageDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (!_cache.containsKey(id)) {
      throw Exception('Image not found: $id');
    }

    return _cache[id]!;
  }

  /// Load image bytes from assets (for display)
  Future<Uint8List> loadImageBytes(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);
    return byteData.buffer.asUint8List();
  }

  @override
  Future<Uint8List?> fetchAndConvertImage(String imageId) async {
    // Check bytes cache first
    if (_bytesCache.containsKey(imageId)) {
      return _bytesCache[imageId];
    }

    // Get metadata to find image path
    if (!_cache.containsKey(imageId)) {
      return null;
    }

    final metadata = _cache[imageId]!;
    if (metadata.imagePath == null) {
      return null;
    }

    try {
      // Load from assets
      final bytes = await loadImageBytes(metadata.imagePath!);
      _bytesCache[imageId] = bytes;
      return bytes;
    } catch (e) {
      print('Error loading mock image: $e');
      return null;
    }
  }
}
