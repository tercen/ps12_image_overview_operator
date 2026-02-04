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
import '../models/image_metadata_impl.dart';

/// Real Tercen implementation of ImageService.
///
/// Downloads ZIP files from Tercen, extracts TIFF images from ImageResults/,
/// converts them to PNG, and returns an ImageCollection.
class TercenImageService implements ImageService {
  final TercenUrlParser _urlParser;
  final ImageService _mockService;

  TercenImageService(this._urlParser, this._mockService);

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
      final resolver = DocumentIdResolver(_urlParser);
      final resolvedIds = await resolver.resolveDocumentId();

      if (resolvedIds == null || resolvedIds.documentId == null) {
        print('⚠️ Could not resolve document ID - using mocks');
        return _mockService.loadImages();
      }

      print('✓ Resolved document ID: ${resolvedIds.documentId}');

      // Download the ZIP file
      final zipBytes = await _downloadZipFile(resolvedIds.documentId!);

      if (zipBytes == null) {
        print('⚠️ Failed to download ZIP file - using mocks');
        return _mockService.loadImages();
      }

      print('✓ Downloaded ZIP file: ${zipBytes.length} bytes');

      // Extract and process images
      final images = await _processZipFile(zipBytes);

      if (images.isEmpty) {
        print('⚠️ No images found in ZIP - using mocks');
        return _mockService.loadImages();
      }

      print('✓ Loaded ${images.length} images from Tercen');
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
    // For now, delegate to mock service
    // In a full implementation, we'd cache the images
    return _mockService.getImageDetails(id);
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

  /// Processes a ZIP file and extracts images.
  Future<List<ImageMetadata>> _processZipFile(Uint8List zipBytes) async {
    final images = <ImageMetadata>[];

    try {
      print('🔍 Processing ZIP file...');

      // Decode ZIP archive
      final archive = ZipDecoder().decodeBytes(zipBytes);
      print('📋 Archive contains ${archive.files.length} files');

      // Find TIFF files in ImageResults/ directory
      final tiffFiles = archive.files.where((file) {
        final name = file.name.toLowerCase();
        return (name.contains('imageresults/') || name.contains('imageresults\\')) &&
            (name.endsWith('.tif') || name.endsWith('.tiff')) &&
            !file.isFile == false; // Ensure it's a file, not a directory
      }).toList();

      print('📋 Found ${tiffFiles.length} TIFF files in ImageResults/');

      if (tiffFiles.isEmpty) {
        // Try looking for TIFFs anywhere in the archive
        final allTiffs = archive.files.where((file) {
          final name = file.name.toLowerCase();
          return (name.endsWith('.tif') || name.endsWith('.tiff')) && file.isFile;
        }).toList();

        print('📋 Found ${allTiffs.length} TIFF files total in archive');

        if (allTiffs.isNotEmpty) {
          tiffFiles.addAll(allTiffs);
        }
      }

      // Process each TIFF file
      for (final file in tiffFiles) {
        final image = await _processTiffFile(file);
        if (image != null) {
          images.add(image);
        }
      }

      print('✓ Processed ${images.length} images');
    } catch (e) {
      print('✗ Error processing ZIP: $e');
    }

    return images;
  }

  /// Processes a single TIFF file from the archive.
  Future<ImageMetadata?> _processTiffFile(ArchiveFile file) async {
    try {
      // Get filename without path
      final filename = file.name.split('/').last.split('\\').last;

      // Parse metadata from filename
      final parsed = PamGeneFilenameParser.parse(filename);

      if (parsed == null) {
        print('⚠️ Could not parse filename: $filename');
        return null;
      }

      // Get file content
      final tiffBytes = Uint8List.fromList(file.content);

      // Convert TIFF to PNG
      final pngBytes = TiffConverter.convertToPng(tiffBytes);

      if (pngBytes == null) {
        print('⚠️ Could not convert TIFF: $filename');
        return null;
      }

      print('✓ Converted: $filename (${pngBytes.length} bytes)');

      return ImageMetadataImpl(
        id: filename,
        filename: filename,
        barcode: parsed['barcode'],
        well: parsed['well'],
        field: parsed['field'],
        cycle: parsed['pumpCycle'],
        exposureTime: parsed['exposureTime'],  // T value: 5, 10, 25, 50, 100 ms
        imageIndex: parsed['imageIndex'],      // I value: sequential capture number
        bytes: pngBytes,
      );
    } catch (e) {
      print('✗ Error processing TIFF ${file.name}: $e');
      return null;
    }
  }

}
