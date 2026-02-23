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

/// Real Tercen implementation of ImageService with lazy per-file decompression.
///
/// Strategy:
/// - On startup: parse the ZIP once with ZipDecoder — this reads only compressed
///   bytes into ArchiveFile objects (no decompression yet, so startup is fast).
/// - On demand: decompress a single TIFF only when its grid cell becomes visible,
///   then convert to PNG and cache the result.
/// - Between each conversion an event-loop yield allows the spinner and
///   status text to update.
class TercenImageService implements ImageService {
  final TercenUrlParser _urlParser;
  final ImageBytesCache _cache;

  /// ArchiveFile objects keyed by archive entry path.
  /// Content is NOT decompressed until explicitly accessed via file.content.
  Map<String, ArchiveFile>? _archiveIndex;

  /// Map of image ID → archive entry path
  final Map<String, String> _imageEntryPaths = {};

  /// Cached image metadata
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
    // Yield so the status text renders before any synchronous work begins.
    await Future.delayed(Duration.zero);

    if (!_urlParser.hasValidContext && _urlParser.taskId == null) {
      throw Exception(
        'No valid Tercen context. Check taskId and token parameters.',
      );
    }

    print('🔍 Loading images from Tercen API...');

    final resolver = DocumentIdResolver(_urlParser);
    final resolvedIds = await resolver.resolveDocumentId();

    if (resolvedIds == null || resolvedIds.documentId == null) {
      throw Exception('Could not resolve document ID from Tercen context.');
    }

    print('✓ Resolved document ID: ${resolvedIds.documentId}');

    onStatus?.call('Downloading image archive...');
    final zipBytes = await _downloadZipFile(resolvedIds.documentId!);

    if (zipBytes == null) {
      throw Exception(
        'Failed to download image archive (document: ${resolvedIds.documentId}).',
      );
    }

    print('✓ Downloaded ZIP file: ${zipBytes.length} bytes');

    onStatus?.call('Indexing images...');
    // Yield so "Indexing images..." appears before the synchronous ZIP parse.
    await Future.delayed(Duration.zero);

    final images = await _indexZipContents(zipBytes, onStatus: onStatus);

    if (images.isEmpty) {
      throw Exception('No TIFF images found in archive.');
    }

    _imageMetadata = images;
    print('✓ Indexed ${images.length} images (lazy decompression enabled)');
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
    if (_cache.contains(imageId)) {
      return _cache.get(imageId);
    }

    if (_archiveIndex == null) {
      print('⚠️ No archive loaded for image: $imageId');
      return null;
    }

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

  /// Decompresses a single TIFF and converts it to PNG.
  ///
  /// An event-loop yield before the synchronous work gives the spinner and
  /// any pending rebuilds a chance to run between conversions.
  Future<void> _convertImage(_ConversionRequest request) async {
    // Yield before heavy synchronous work so the UI can update.
    await Future.delayed(Duration.zero);

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

      final archiveFile = _archiveIndex?[entryPath];
      if (archiveFile == null) {
        print('⚠️ No archive entry for: $entryPath');
        request.completer.complete(null);
        return;
      }

      // Lazy decompression: only this one file's compressed bytes are inflated.
      final tiffData = Uint8List.fromList(archiveFile.content as List<int>);

      // Synchronous TIFF → PNG conversion (auto-scaled brightness).
      final pngBytes = TiffConverter.convertToPng(tiffData);

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

  /// Downloads the ZIP file from Tercen using efficient single-allocation
  /// byte concatenation to avoid the intermediate List<int> expansion.
  Future<Uint8List?> _downloadZipFile(String documentId) async {
    try {
      print('🔍 Downloading ZIP file: $documentId');

      final fileService = tercen.ServiceFactory().fileService;
      final stream = fileService.download(documentId);

      final chunks = <Uint8List>[];
      int totalLength = 0;
      await for (final chunk in stream) {
        final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        chunks.add(bytes);
        totalLength += bytes.length;
      }

      final result = Uint8List(totalLength);
      int offset = 0;
      for (final chunk in chunks) {
        result.setAll(offset, chunk);
        offset += chunk.length;
      }

      print('✓ Downloaded: $totalLength bytes');
      return result;
    } catch (e) {
      print('✗ Download failed: $e');
      return null;
    }
  }

  /// Parses the ZIP structure and indexes ArchiveFile objects by path.
  ///
  /// ZipDecoder.decodeBytes() reads only compressed bytes — it does NOT
  /// decompress (inflate) any file content.  All decompression is deferred
  /// until file.content is first accessed in _convertImage().
  Future<List<ImageMetadata>> _indexZipContents(
    Uint8List zipBytes, {
    void Function(String)? onStatus,
  }) async {
    final images = <ImageMetadata>[];

    try {
      print('🔍 Parsing ZIP archive...');

      // Synchronous parse — reads headers + stores compressed bytes per entry.
      // Does NOT decompress any TIFF data.
      final archive = ZipDecoder().decodeBytes(zipBytes);
      print('📋 Archive contains ${archive.files.length} entries');

      // Build an index without decompressing (file.content is NOT called here).
      _archiveIndex = {};
      for (final file in archive.files) {
        if (file.isFile) {
          _archiveIndex![file.name] = file;
        }
      }

      onStatus?.call('Building image list...');

      // Prefer TIFF files under ImageResults/; fall back to all TIFFs.
      final tiffEntries = _archiveIndex!.keys.where((name) {
        final lower = name.toLowerCase();
        return (lower.contains('imageresults/') ||
                lower.contains('imageresults\\')) &&
            (lower.endsWith('.tif') || lower.endsWith('.tiff'));
      }).toList();

      print('📋 Found ${tiffEntries.length} TIFF files in ImageResults/');

      final entries = tiffEntries.isNotEmpty
          ? tiffEntries
          : _archiveIndex!.keys.where((name) {
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
