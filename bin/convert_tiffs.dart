import 'dart:io';
import 'package:ps12_image_overview/utils/tiff_converter.dart';

/// Command-line script to convert TIFF images to PNG
///
/// Usage: dart run bin/convert_tiffs.dart <input_dir> <output_dir>
void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('Usage: dart run bin/convert_tiffs.dart <input_dir> <output_dir>');
    exit(1);
  }

  final inputDir = Directory(arguments[0]);
  final outputDir = Directory(arguments[1]);

  if (!await inputDir.exists()) {
    print('Error: Input directory does not exist: ${inputDir.path}');
    exit(1);
  }

  // Create output directory if it doesn't exist
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  print('Converting TIFF files from ${inputDir.path} to ${outputDir.path}');
  print('');

  int converted = 0;
  int failed = 0;

  await for (final entity in inputDir.list()) {
    if (entity is File && entity.path.toLowerCase().endsWith('.tif')) {
      final filename = entity.uri.pathSegments.last;
      final basename = filename.substring(0, filename.length - 4);
      final outputPath = '${outputDir.path}/$basename.png';

      try {
        print('Converting $filename...');
        final tiffBytes = await entity.readAsBytes();
        final pngBytes = TiffConverter.convertToPng(tiffBytes);

        if (pngBytes != null) {
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(pngBytes);
          converted++;
          print('  ✓ Saved to $basename.png');
        } else {
          failed++;
          print('  ✗ Conversion failed (returned null)');
        }
      } catch (e) {
        failed++;
        print('  ✗ Error: $e');
      }
    }
  }

  print('');
  print('Conversion complete!');
  print('  Converted: $converted');
  print('  Failed: $failed');
}
