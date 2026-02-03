import 'image_metadata.dart';

/// Collection of images with metadata aggregation
class ImageCollection {
  final List<ImageMetadata> images;

  ImageCollection({required this.images});

  /// Get unique barcodes sorted alphanumerically
  List<String> get barcodes {
    final uniqueBarcodes = images.map((img) => img.barcode).toSet().toList();
    uniqueBarcodes.sort();
    return uniqueBarcodes;
  }

  /// Get unique wells sorted numerically
  List<int> get wells {
    final uniqueWells = images.map((img) => img.well).toSet().toList();
    uniqueWells.sort();
    return uniqueWells;
  }

  /// Get unique cycles sorted ascending
  List<int> get cycles {
    final uniqueCycles = images.map((img) => img.cycle).toSet().toList();
    uniqueCycles.sort();
    return uniqueCycles;
  }

  /// Get unique exposure times sorted ascending
  List<int> get exposureTimes {
    final uniqueExposures = images.map((img) => img.exposureTime).toSet().toList();
    uniqueExposures.sort();
    return uniqueExposures;
  }

  /// Get default cycle (latest/highest)
  int? get defaultCycle {
    if (cycles.isEmpty) return null;
    return cycles.last;
  }

  /// Get default exposure time (longest/highest)
  int? get defaultExposureTime {
    if (exposureTimes.isEmpty) return null;
    return exposureTimes.last;
  }

  /// Filter images by criteria
  List<ImageMetadata> filter({int? cycle, int? exposureTime}) {
    return images.where((img) {
      if (cycle != null && img.cycle != cycle) return false;
      if (exposureTime != null && img.exposureTime != exposureTime) return false;
      return true;
    }).toList();
  }
}
