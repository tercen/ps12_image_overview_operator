import 'dart:async';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
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

// Top-level function required by compute() — decodes ZIP and extracts all file
// bytes into a plain map that can cross isolate boundaries.
Map<String, Uint8List> _decodeZipInIsolate(Uint8List zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  final result = <String, Uint8List>{};
  for (final file in archive.files) {
    if (file.isFile) {
      result[file.name] = Uint8List.fromList(file.content as List<int>);
    }
  }
  return result;
}

// Top-level function required by compute() — converts a single TIFF to PNG.
Uint8List? _convertTiffInIsolate(Uint8List tiffBytes) {
  return TiffConverter.convertToPng(tiffBytes);
}

/// Real Tercen implementation of ImageService with lazy loading.
///
/// Features:
/// - Lazy loading: Downloads ZIP once, extracts metadata from filenames
/// - On-demand conversion: TIFF→PNG conversion happens when image is displayed
/// - Caching: Stores converted PNG bytes to avoid redundant conversions
/// - Request throttling: Limits concurrent conversions to prevent UI jank
/// - Off-thread work: ZIP decode and TIFF conversion run via compute()
class TercenImageService implements ImageService {
  final TercenUrlParser _urlParser;
  final ImageBytesCache _cache;

  /// Decoded TIFF bytes keyed by archive entry path (filename → raw TIFF bytes)
  Map<String, Uint8List>? _tiffBytes;

  /// Map of image ID to archive entry path
  final Map<String, String> _imageEntryPaths = {};

  /// Cached image metadata loaded on startup
  List<ImageMetadata>? _imageMetadata;

  /// Maximum number of concurrent image conversions
  static const int _maxConcurrentConversions = 3;

  /// Current number of active conversions
  int _activeConversions = 0;

  /// Queue of pending conversion requests
  final List<_ConversionRequest> _conversionQueue = [];

  TercenImageService(this._urlParser) : _cache = ImageBytesCache();

  @override
  Future<ImageCollection> loadImages({void Function(String)? onStatus}) async {
    onStatus?.call('Connecting to Tercen...');

    if (!_urlParser.hasValidContext && _urlParser.taskId == null) {
      throw Exception(
        'No valid Tercen context. Check taskId and token parameters.',
      );
    }

    print('🔍 Loading images from Tercen API...');
    print('📋 URL Parser: $_urlParser');

    // Resolve document ID
    print('🔍 Resolving document ID...');
    final resolver = DocumentIdResolver(_urlParser);
    final resolvedIds = await resolver.resolveDocumentId();

    if (resolvedIds == null || resolvedIds.documentId == null) {
      throw Exception('Could not resolve document ID from Tercen context.');
    }

    print('✓ Resolved document ID: ${resolvedIds.documentId}');

    // Download the ZIP file
    onStatus?.call('Downloading image archive...');
    final zipBytes = await _downloadZipFile(resolvedIds.documentId!);

    if (zipBytes == null) {
      throw Exception(
        'Failed to download image archive (document: ${resolvedIds.documentId}).',
      );
    }

    print('✓ Downloaded ZIP file: ${zipBytes.length} bytes');

    // Decode ZIP and index contents (heavy work runs in isolate)
    onStatus?.call('Unpacking archive\u2014this may take a moment...');
    final images = await _indexZipContents(zipBytes, onStatus: onStatus);

    if (images.isEmpty) {
      throw Exception('No TIFF images found in archive.');
    }

    _imageMetadata = images;
    print('✓ Indexed ${images.length} images (lazy loading enabled)');
    return ImageCollection(images: images);
  }

  @override
  Future<ImageMetadata> getImageDetails(String id) async {
    if (_imageMetadata != null) {
      final found = _imageMetadata!.where((img) => img.id == id);
      if (found.isNotEmpty) return found.first;
    }
    throw Exception('Image not found: $id');
  }

  @override
  Future<Uint8List?> fetchAndConvertImage(String imageId) async {
    // Check cache first
    if (_cache.contains(imageId)) {
      return _cache.get(imageId);
    }

    if (_tiffBytes == null) {
      print('⚠️ No archive loaded for image: $imageId');
      return null;
    }

    // Create a completer for this conversion request
    final completer = Completer<Uint8List?>();
    final request = _ConversionRequest(imageId, completer);

    _conversionQueue.add(request);
    _processQueue();

    return completer.future;
  }

  /// Processes the conversion queue, respecting the concurrency limit.
  void _processQueue() {
    while (_activeConversions < _maxConcurrentConversions &&
        _conversionQueue.isNotEmpty) {
      final request = _conversionQueue.removeAt(0);
      _activeConversions++;

      _convertImage(request).then((_) {
        _activeConversions--;
        _processQueue();
      });
    }
  }

  /// Converts a single image from TIFF to PNG in an isolate.
  Future<void> _convertImage(_ConversionRequest request) async {
    try {
      if (_cache.contains(request.imageId)) {
        request.completer.complete(_cache.get(request.imageId));
        return;
      }

      final entryPath = _imageEntryPaths[request.imageId];
      if (entryPath == null) {
        print('⚠️ No entry path for image: ${request.imageId}');
        request.completer.complete(null);
        return;
      }

      final tiffData = _tiffBytes![entryPath];
      if (tiffData == null) {
        print('⚠️ No TIFF bytes for entry: $entryPath');
        request.completer.complete(null);
        return;
      }

      // Run conversion in isolate to keep UI thread free
      final pngBytes = await compute(_convertTiffInIsolate, tiffData);

      if (pngBytes != null) {
        _cache.put(request.imageId, pngBytes);
        print('✓ Converted: ${request.imageId} (${pngBytes.length} bytes)');
      } else {
        print('⚠️ Failed to convert TIFF: ${request.imageId}');
      }

      request.completer.complete(pngBytes);
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

  /// Decodes the ZIP in an isolate, indexes contents, and creates metadata.
  Future<List<ImageMetadata>> _indexZipContents(
    Uint8List zipBytes, {
    void Function(String)? onStatus,
  }) async {
    final images = <ImageMetadata>[];

    try {
      print('🔍 Decoding ZIP in isolate...');

      // Heavy decompression runs off the main thread
      _tiffBytes = await compute(_decodeZipInIsolate, zipBytes);
      print('📋 Archive contains ${_tiffBytes!.length} files');

      onStatus?.call('Indexing images...');

      // Find TIFF files in ImageResults/ directory
      final tiffEntries = _tiffBytes!.keys.where((name) {
        final lower = name.toLowerCase();
        return (lower.contains('imageresults/') ||
                lower.contains('imageresults\\')) &&
            (lower.endsWith('.tif') || lower.endsWith('.tiff'));
      }).toList();

      print('📋 Found ${tiffEntries.length} TIFF files in ImageResults/');

      // Fall back to all TIFFs in archive if none found under ImageResults/
      final entries = tiffEntries.isNotEmpty
          ? tiffEntries
          : _tiffBytes!.keys.where((name) {
              final lower = name.toLowerCase();
              return lower.endsWith('.tif') || lower.endsWith('.tiff');
            }).toList();

      if (tiffEntries.isEmpty) {
        print('📋 Using ${entries.length} TIFF files from entire archive');
      }

      for (final entryPath in entries) {
        final metadata = _createMetadataFromPath(entryPath);
        if (metadata != null) {
          images.add(metadata);
          _imageEntryPaths[metadata.id] = entryPath;
        }
      }

      print('✓ Indexed ${images.length} images');
    } catch (e) {
      print('✗ Error indexing ZIP: $e');
    }

    return images;
  }

  /// Creates metadata from an archive entry path without reading image bytes.
  ImageMetadata? _createMetadataFromPath(String entryPath) {
    try {
      final filename = entryPath.split('/').last.split('\\').last;
      final parsed = PamGeneFilenameParser.parse(filename);

      if (parsed == null) {
        print('⚠️ Could not parse filename: $filename');
        return null;
      }

      return ImageMetadataImpl(
        id: filename,
        filename: filename,
        barcode: parsed['barcode'],
        well: parsed['well'],
        field: parsed['field'],
        cycle: parsed['pumpCycle'],
        exposureTime: parsed['exposureTime'],
        imageIndex: parsed['imageIndex'],
        bytes: null,
      );
    } catch (e) {
      print('✗ Error creating metadata for $entryPath: $e');
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
