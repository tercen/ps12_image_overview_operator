/// Parser for PamGene TIFF filename convention
///
/// Format: {barcode}_W{well}_F{field}_T{exposureTime}_P{pumpCycle}_I{imageIndex}_A{array}.tif
/// Example: 641070616_W1_F1_T100_P94_I493_A30.tif
///
/// Field meanings:
/// - T = Exposure Time (values like 5, 10, 25, 50, 100 ms)
/// - P = Pump Cycle number
/// - I = Image Index (sequential capture number)
class PamGeneFilenameParser {
  static final _pattern = RegExp(
    r'(\d+)_W(\d+)_F(\d+)_T(\d+)_P(\d+)_I(\d+)_A(\d+)',
  );

  /// Parse filename and return metadata map
  static Map<String, dynamic>? parse(String filename) {
    final match = _pattern.firstMatch(filename);

    if (match == null) return null;

    return {
      'barcode': match.group(1)!,
      'well': int.parse(match.group(2)!),
      'field': int.parse(match.group(3)!),
      'exposureTime': int.parse(match.group(4)!),  // T = Exposure Time
      'pumpCycle': int.parse(match.group(5)!),
      'imageIndex': int.parse(match.group(6)!),    // I = Image Index
      'array': int.parse(match.group(7)!),
    };
  }

  /// Extract barcode from filename
  static String getBarcode(String filename) {
    final parsed = parse(filename);
    return parsed?['barcode'] ?? '';
  }

  /// Extract well number from filename
  static int getWell(String filename) {
    final parsed = parse(filename);
    return parsed?['well'] ?? 0;
  }

  /// Extract field number from filename
  static int getField(String filename) {
    final parsed = parse(filename);
    return parsed?['field'] ?? 0;
  }

  /// Extract pump cycle from filename
  static int getPumpCycle(String filename) {
    final parsed = parse(filename);
    return parsed?['pumpCycle'] ?? 0;
  }

  /// Extract exposure time from filename (T value: 5, 10, 25, 50, 100 ms)
  static int getExposureTime(String filename) {
    final parsed = parse(filename);
    return parsed?['exposureTime'] ?? 0;
  }

  /// Extract image index from filename (I value)
  static int getImageIndex(String filename) {
    final parsed = parse(filename);
    return parsed?['imageIndex'] ?? 0;
  }
}
