import 'dart:async';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';
import '../../domain/models/image_metadata.dart';
import '../../utils/tercen_url_parser.dart';
import '../../utils/document_id_resolver.dart';
import '../../utils/pamgene_filename_parser.dart';
import '../../utils/tiff_converter.dart';
import '../../utils/image_bytes_cache.dart';
import '../models/image_metadata_impl.dart';

/// Real Tercen implementation of ImageService with lazy loading.
///
/// Features:
/// - Lazy loading: Downloads ZIP once, extracts metadata from filenames
/// - On-demand conversion: TIFF→PNG conversion happens when image is displayed
/// - Caching: Stores converted PNG bytes to avoid redundant conversions
/// - Request throttling: Limits concurrent conversions to prevent UI freeze
class TercenImageService implements ImageService {
  final TercenUrlParser _urlParser;
  final ImageService _mockService;
  final ImageBytesCache _cache;

  /// Cached ZIP archive for on-demand extraction
  Archive? _archive;

  /// Map of image ID to archive file entry path
  final Map<String, String> _imageEntryPaths = {};

  /// Cached image metadata loaded on startup
  List<ImageMetadata>? _imageMetadata;

  /// Maximum number of concurrent image conversions
  static const int _maxConcurrentConversions = 3;

  /// Current number of active conversions
  int _activeConversions = 0;

  /// Queue of pending conversion requests
  final List<_ConversionRequest> _conversionQueue = [];

  TercenImageService(this._urlParser, this._mockService)
      : _cache = ImageBytesCache();

  @override
  Future<ImageCollection> loadImages() async {
    try {
      // Validate context
      if (!_urlParser.hasValidContext && _urlParser.taskId == null) {
        print('⚠️ No valid Tercen context - using mocks');
        return _mockService.loadImages();
      }

      print('🔍 Loading images from Tercen API...');
      print('📋 URL Parser: $_urlParser');

      // Resolve document ID
      print('🔍 Resolving document ID...');
      final resolver = DocumentIdResolver(_urlParser);
      final resolvedIds = await resolver.resolveDocumentId();

      if (resolvedIds == null || resolvedIds.documentId == null) {
        print('⚠️ Could not resolve document ID - using mocks');
        return _mockService.loadImages();
      }

      print('✓ Resolved document ID: ${resolvedIds.documentId}');

      // Download the ZIP file (we need to keep it for on-demand extraction)
      final zipBytes = await _downloadZipFile(resolvedIds.documentId!);

      if (zipBytes == null) {
        print('⚠️ Failed to download ZIP file - using mocks');
        return _mockService.loadImages();
      }

      print('✓ Downloaded ZIP file: ${zipBytes.length} bytes');

      // Parse ZIP to get file list (metadata only, no conversion yet)
      final images = await _indexZipContents(zipBytes);

      if (images.isEmpty) {
        print('⚠️ No images found in ZIP - using mocks');
        return _mockService.loadImages();
      }

      _imageMetadata = images;
      print('✓ Indexed ${images.length} images from Tercen (lazy loading enabled)');
      return ImageCollection(images: images);
    } catch (e, stackTrace) {
      print('✗ Error loading from Tercen: $e');
      print('Stack trace: $stackTrace');
      print('Falling back to mock data');
      return _mockService.loadImages();
    }
  }

  @override
  Future<ImageMetadata> getImageDetails(String id) async {
    // Check if we have cached metadata
    if (_imageMetadata != null) {
      final found = _imageMetadata!.where((img) => img.id == id);
      if (found.isNotEmpty) {
        return found.first;
      }
    }
    // Fallback to mock service
    return _mockService.getImageDetails(id);
  }

  @override
  Future<Uint8List?> fetchAndConvertImage(String imageId) async {
    // Check cache first
    if (_cache.contains(imageId)) {
      return _cache.get(imageId);
    }

    // If no archive loaded, return null
    if (_archive == null) {
      print('⚠️ No archive loaded for image: $imageId');
      return null;
    }

    // Create a completer for this conversion request
    final completer = Completer<Uint8List?>();
    final request = _ConversionRequest(imageId, completer);

    // Add to queue and try to process
    _conversionQueue.add(request);
    _processQueue();

    // Wait for the conversion to complete
    return completer.future;
  }

  /// Processes the conversion queue, respecting the concurrency limit.
  void _processQueue() {
    // Process as many requests as we can within the concurrency limit
    while (_activeConversions < _maxConcurrentConversions &&
        _conversionQueue.isNotEmpty) {
      final request = _conversionQueue.removeAt(0);
      _activeConversions++;

      // Start the conversion (fire and forget)
      _convertImage(request).then((_) {
        _activeConversions--;
        // Process next item in queue
        _processQueue();
      });
    }
  }

  /// Actually converts a single image from TIFF to PNG.
  Future<void> _convertImage(_ConversionRequest request) async {
    try {
      // Check cache again (may have been cached while in queue)
      if (_cache.contains(request.imageId)) {
        request.completer.complete(_cache.get(request.imageId));
        return;
      }

      // Find the archive entry
      final entryPath = _imageEntryPaths[request.imageId];
      if (entryPath == null) {
        print('⚠️ No entry path for image: ${request.imageId}');
        request.completer.complete(null);
        return;
      }

      // Find the file in the archive
      final file = _archive!.files.firstWhere(
        (f) => f.name == entryPath,
        orElse: () => throw StateError('File not found in archive: $entryPath'),
      );

      // Get file content and convert
      final tiffBytes = Uint8List.fromList(file.content);
      final pngBytes = TiffConverter.convertToPng(tiffBytes);

      if (pngBytes != null) {
        // Cache the converted PNG
        _cache.put(request.imageId, pngBytes);
        print('✓ Lazy-loaded: ${request.imageId} (${pngBytes.length} bytes)');
      } else {
        print('⚠️ Failed to convert TIFF: ${request.imageId}');
      }

      request.completer.complete(pngBytes);
    } on StateError catch (e) {
      print('⚠️ Image not found: ${request.imageId} - $e');
      request.completer.complete(null);
    } catch (e) {
      print('✗ Error converting image ${request.imageId}: $e');
      request.completer.complete(null);
    }
  }

  /// Downloads a ZIP file from Tercen.
  Future<Uint8List?> _downloadZipFile(String documentId) async {
    try {
      print('🔍 Downloading ZIP file: $documentId');

      final fileService = tercen.ServiceFactory().fileService;
      final stream = fileService.download(documentId);

      final chunks = <List<int>>[];
      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
      print('✓ Downloaded: ${bytes.length} bytes');

      return bytes;
    } catch (e) {
      print('✗ Download failed: $e');
      return null;
    }
  }

  /// Indexes ZIP contents and creates metadata without converting images.
  Future<List<ImageMetadata>> _indexZipContents(Uint8List zipBytes) async {
    final images = <ImageMetadata>[];

    try {
      print('🔍 Indexing ZIP contents...');

      // Decode and store ZIP archive for later on-demand extraction
      _archive = ZipDecoder().decodeBytes(zipBytes);
      print('📋 Archive contains ${_archive!.files.length} files');

      // Find TIFF files in ImageResults/ directory
      final tiffFiles = _archive!.files.where((file) {
        final name = file.name.toLowerCase();
        return (name.contains('imageresults/') ||
                name.contains('imageresults\\')) &&
            (name.endsWith('.tif') || name.endsWith('.tiff')) &&
            file.isFile;
      }).toList();

      print('📋 Found ${tiffFiles.length} TIFF files in ImageResults/');

      if (tiffFiles.isEmpty) {
        // Try looking for TIFFs anywhere in the archive
        final allTiffs = _archive!.files.where((file) {
          final name = file.name.toLowerCase();
          return (name.endsWith('.tif') || name.endsWith('.tiff')) &&
              file.isFile;
        }).toList();

        print('📋 Found ${allTiffs.length} TIFF files total in archive');

        if (allTiffs.isNotEmpty) {
          tiffFiles.addAll(allTiffs);
        }
      }

      // Create metadata for each TIFF file (without converting)
      for (final file in tiffFiles) {
        final metadata = _createMetadataFromFile(file);
        if (metadata != null) {
          images.add(metadata);
          // Store entry path for later on-demand extraction
          _imageEntryPaths[metadata.id] = file.name;
        }
      }

      print('✓ Indexed ${images.length} images (bytes not loaded yet)');
    } catch (e) {
      print('✗ Error indexing ZIP: $e');
    }

    return images;
  }

  /// Creates metadata from a TIFF file without converting it.
  ImageMetadata? _createMetadataFromFile(ArchiveFile file) {
    try {
      // Get filename without path
      final filename = file.name.split('/').last.split('\\').last;

      // Parse metadata from filename
      final parsed = PamGeneFilenameParser.parse(filename);

      if (parsed == null) {
        print('⚠️ Could not parse filename: $filename');
        return null;
      }

      // Create metadata WITHOUT image bytes (lazy loading)
      return ImageMetadataImpl(
        id: filename,
        filename: filename,
        barcode: parsed['barcode'],
        well: parsed['well'],
        field: parsed['field'],
        cycle: parsed['pumpCycle'],
        exposureTime: parsed['exposureTime'], // T value: 5, 10, 25, 50, 100 ms
        imageIndex: parsed['imageIndex'], // I value: sequential capture number
        bytes: null, // Will be loaded on-demand
      );
    } catch (e) {
      print('✗ Error creating metadata for ${file.name}: $e');
      return null;
    }
  }

  /// Returns cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_images': _cache.length,
      'current_size_mb': _cache.currentSizeMB.toStringAsFixed(2),
      'max_size_mb': _cache.maxSizeMB.toStringAsFixed(2),
      'cache_usage_percent':
          ((_cache.currentSizeMB / _cache.maxSizeMB) * 100).toStringAsFixed(1),
    };
  }

  /// Clears the image cache
  void clearCache() {
    _cache.clear();
    print('Image cache cleared');
  }
}

/// Internal class to represent a conversion request in the queue.
class _ConversionRequest {
  final String imageId;
  final Completer<Uint8List?> completer;

  _ConversionRequest(this.imageId, this.completer);
}
