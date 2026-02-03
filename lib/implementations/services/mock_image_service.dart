import 'package:flutter/services.dart';
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';
import '../../domain/models/image_metadata.dart';
import '../../utils/pamgene_filename_parser.dart';
import '../models/image_metadata_impl.dart';

/// Mock implementation of ImageService using pre-converted PNG assets
class MockImageService implements ImageService {
  final Map<String, ImageMetadata> _cache = {};

  MockImageService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock data for QC grid demonstration
    // 3 barcodes × 4 wells = 12 images
    // All at cycle P94, exposure I488, temperature T100, field F1
    //
    // NOTE: For proper QC view, all images must have the SAME cycle and exposure time.
    // This allows filtering by (cycle, exposure) to show a complete grid snapshot.
    // Production data may have images at different exposures, but for mock demonstration,
    // we standardize the metadata to I488 to show a complete 3×4 grid.

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
        // Standardize all images to exposure I488 for mock demonstration
        // This ensures the complete grid displays when filtered
        _cache[filename] = ImageMetadataImpl(
          id: filename,
          filename: filename,
          imagePath: 'assets/$filename',
          barcode: parsed['barcode'],
          well: parsed['well'],
          field: parsed['field'],
          cycle: parsed['pumpCycle'],
          exposureTime: 488, // Standardized for mock
          temperature: parsed['temperature'],
        );
      }
    }
  }

  @override
  Future<ImageCollection> loadImages() async {
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
}
