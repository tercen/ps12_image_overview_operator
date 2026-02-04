import 'package:flutter/foundation.dart';
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';
import '../../domain/models/image_metadata.dart';

/// State management for image overview screen
class ImageOverviewProvider with ChangeNotifier {
  final ImageService _imageService;

  ImageOverviewProvider(this._imageService);

  ImageCollection? _imageCollection;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  int? _selectedCycle;
  int? _selectedExposureTime;

  // Getters
  ImageCollection? get imageCollection => _imageCollection;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int? get selectedCycle => _selectedCycle;
  int? get selectedExposureTime => _selectedExposureTime;

  /// Get filtered images based on current filter criteria
  List<ImageMetadata> get filteredImages {
    if (_imageCollection == null) return [];

    return _imageCollection!.filter(
      cycle: _selectedCycle,
      exposureTime: _selectedExposureTime,
    );
  }

  /// Get unique barcodes in filtered images
  List<String> get filteredBarcodes {
    if (filteredImages.isEmpty) return [];
    final barcodes = filteredImages.map((img) => img.barcode).toSet().toList();
    barcodes.sort();
    return barcodes;
  }

  /// Get unique wells in filtered images
  List<int> get filteredWells {
    if (filteredImages.isEmpty) return [];
    final wells = filteredImages.map((img) => img.well).toSet().toList();
    wells.sort();
    return wells;
  }

  /// Get available cycles for filter dropdown
  List<int> get availableCycles => _imageCollection?.cycles ?? [];

  /// Get available exposure times for filter dropdown
  List<int> get availableExposureTimes => _imageCollection?.exposureTimes ?? [];

  /// Load images from service
  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _imageCollection = await _imageService.loadImages();

      // Set default filters (latest cycle, longest exposure)
      _selectedCycle = _imageCollection?.defaultCycle;
      _selectedExposureTime = _imageCollection?.defaultExposureTime;

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load images: $e';
      debugPrint('Error loading images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set cycle filter
  void setCycle(int? cycle) {
    _selectedCycle = cycle;
    notifyListeners();
  }

  /// Set exposure time filter
  void setExposureTime(int? exposureTime) {
    _selectedExposureTime = exposureTime;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCycle = null;
    _selectedExposureTime = null;
    notifyListeners();
  }

  /// Get image at specific grid position (barcode, well)
  ImageMetadata? getImageAt(String barcode, int well) {
    final matches = filteredImages.where(
      (img) => img.barcode == barcode && img.well == well,
    );
    return matches.isEmpty ? null : matches.first;
  }
}
