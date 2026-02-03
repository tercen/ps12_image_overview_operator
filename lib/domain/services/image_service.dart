import '../models/image_collection.dart';
import '../models/image_metadata.dart';

/// Abstract service interface for loading images
abstract class ImageService {
  /// Load all images
  Future<ImageCollection> loadImages();

  /// Get details for a specific image
  Future<ImageMetadata> getImageDetails(String id);
}
