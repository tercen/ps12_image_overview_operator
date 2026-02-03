import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// TIFF to PNG converter for PamGene microscopy images
///
/// Converts 16-bit grayscale TIFF images (with 12-bit data) to 8-bit PNG format
/// for efficient web display.
class TiffConverter {
  /// Convert 16-bit TIFF to 8-bit PNG
  static Uint8List? convertToPng(Uint8List tiffBytes) {
    final image = decode16BitGrayscaleTiff(tiffBytes);
    if (image == null) return null;

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Decode 16-bit grayscale TIFF
  static img.Image? decode16BitGrayscaleTiff(Uint8List bytes) {
    if (bytes.length < 8) return null;

    final byteData = ByteData.sublistView(bytes);

    // Read TIFF header
    final byteOrder = _readByteOrder(byteData);
    if (byteOrder == null) return null;

    // Read magic number (42)
    final magic = byteOrder == Endian.little
        ? byteData.getUint16(2, Endian.little)
        : byteData.getUint16(2, Endian.big);

    if (magic != 42) return null;

    // Read IFD offset
    final ifdOffset = byteOrder == Endian.little
        ? byteData.getUint32(4, Endian.little)
        : byteData.getUint32(4, Endian.big);

    // Parse IFD entries
    final ifd = _parseIFD(byteData, ifdOffset, byteOrder);
    if (ifd == null) return null;

    // Get image dimensions
    final width = ifd['ImageWidth'] as int?;
    final height = ifd['ImageLength'] as int?;
    final bitsPerSample = ifd['BitsPerSample'] as int? ?? 16;

    if (width == null || height == null) return null;

    // Get strip offsets and byte counts
    final stripOffsets = ifd['StripOffsets'] as List<int>?;
    final stripByteCounts = ifd['StripByteCounts'] as List<int>?;

    if (stripOffsets == null || stripByteCounts == null) return null;

    // Read image data
    final imageData = _readStrips(
      byteData,
      stripOffsets,
      stripByteCounts,
      byteOrder,
    );

    // Convert to 8-bit image
    return _convertTo8Bit(imageData, width, height, bitsPerSample);
  }

  static Endian? _readByteOrder(ByteData byteData) {
    final byte0 = byteData.getUint8(0);
    final byte1 = byteData.getUint8(1);

    if (byte0 == 0x49 && byte1 == 0x49) {
      return Endian.little; // II (Intel)
    } else if (byte0 == 0x4D && byte1 == 0x4D) {
      return Endian.big; // MM (Motorola)
    }

    return null;
  }

  static Map<String, dynamic>? _parseIFD(
    ByteData byteData,
    int offset,
    Endian byteOrder,
  ) {
    final ifd = <String, dynamic>{};

    // Read number of directory entries
    final numEntries = byteData.getUint16(offset, byteOrder);

    int currentOffset = offset + 2;

    for (int i = 0; i < numEntries; i++) {
      final tag = byteData.getUint16(currentOffset, byteOrder);
      final type = byteData.getUint16(currentOffset + 2, byteOrder);
      final count = byteData.getUint32(currentOffset + 4, byteOrder);
      final valueOffset = byteData.getUint32(currentOffset + 8, byteOrder);

      // Map tag to field name
      final fieldName = _getTagName(tag);

      // Read value based on type
      final value = _readIFDValue(byteData, type, count, valueOffset, byteOrder);

      if (fieldName != null) {
        ifd[fieldName] = value;
      }

      currentOffset += 12;
    }

    return ifd;
  }

  static String? _getTagName(int tag) {
    const tagMap = {
      256: 'ImageWidth',
      257: 'ImageLength',
      258: 'BitsPerSample',
      259: 'Compression',
      262: 'PhotometricInterpretation',
      273: 'StripOffsets',
      277: 'SamplesPerPixel',
      278: 'RowsPerStrip',
      279: 'StripByteCounts',
      282: 'XResolution',
      283: 'YResolution',
      296: 'ResolutionUnit',
    };

    return tagMap[tag];
  }

  static dynamic _readIFDValue(
    ByteData byteData,
    int type,
    int count,
    int valueOffset,
    Endian byteOrder,
  ) {
    // Type 3: SHORT (16-bit unsigned)
    if (type == 3) {
      if (count == 1) {
        // Value is in offset field (lower 16 bits)
        return valueOffset & 0xFFFF;
      } else {
        // Multiple values at offset
        final values = <int>[];
        for (int i = 0; i < count; i++) {
          values.add(byteData.getUint16(valueOffset + (i * 2), byteOrder));
        }
        return values;
      }
    }
    // Type 4: LONG (32-bit unsigned)
    else if (type == 4) {
      if (count == 1) {
        return valueOffset;
      } else {
        final values = <int>[];
        for (int i = 0; i < count; i++) {
          values.add(byteData.getUint32(valueOffset + (i * 4), byteOrder));
        }
        return values;
      }
    }

    return null;
  }

  static Uint16List _readStrips(
    ByteData byteData,
    List<int> stripOffsets,
    List<int> stripByteCounts,
    Endian byteOrder,
  ) {
    final totalBytes = stripByteCounts.reduce((a, b) => a + b);
    final pixelCount = totalBytes ~/ 2; // 16-bit = 2 bytes per pixel

    final imageData = Uint16List(pixelCount);
    int pixelIndex = 0;

    for (int i = 0; i < stripOffsets.length; i++) {
      final offset = stripOffsets[i];
      final byteCount = stripByteCounts[i];
      final pixelsInStrip = byteCount ~/ 2;

      for (int j = 0; j < pixelsInStrip; j++) {
        imageData[pixelIndex++] = byteData.getUint16(
          offset + (j * 2),
          byteOrder,
        );
      }
    }

    return imageData;
  }

  static img.Image _convertTo8Bit(
    Uint16List data16,
    int width,
    int height,
    int bitsPerSample,
  ) {
    final image = img.Image(width: width, height: height);

    // PamGene uses 12-bit data in 16-bit container
    // Convert to 8-bit by right-shifting 4 bits (divide by 16)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final value16 = data16[index];

        // Convert 12-bit (0-4095) to 8-bit (0-255)
        // Right-shift by 4: value16 >> 4
        final value8 = (value16 >> 4).clamp(0, 255);

        // Set pixel (grayscale)
        image.setPixelRgba(x, y, value8, value8, value8, 255);
      }
    }

    return image;
  }
}
