import 'dart:typed_data';

import '../models/image_collection.dart';
import '../models/image_metadata.dart';

/// Abstract service interface for loading images
abstract class ImageService {
  /// Load image metadata (without image bytes for lazy loading)
  ///
  /// Returns an ImageCollection with metadata for all available images.
  /// The actual image bytes are loaded on-demand via [fetchAndConvertImage].
  /// [onStatus] is called with human-readable progress messages during loading.
  Future<ImageCollection> loadImages({void Function(String)? onStatus});

  /// Get details for a specific image
  Future<ImageMetadata> getImageDetails(String id);

  /// Fetch and convert a single image on-demand (lazy loading)
  ///
  /// Downloads the TIFF from the archive and converts it to PNG.
  /// Results are cached to avoid redundant downloads/conversions.
  /// Returns null if the image cannot be loaded or converted.
  Future<Uint8List?> fetchAndConvertImage(String imageId);
}
