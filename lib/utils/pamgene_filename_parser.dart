/// Parser for PamGene TIFF filename convention
///
/// Format: {barcode}_W{well}_F{field}_T{temperature}_P{pumpCycle}_I{intensity}_A{array}.tif
/// Example: 641070616_W1_F1_T100_P94_I493_A30.tif
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
      'temperature': int.parse(match.group(4)!),
      'pumpCycle': int.parse(match.group(5)!),
      'intensity': int.parse(match.group(6)!),
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

  /// Extract exposure time (intensity) from filename
  static int getExposureTime(String filename) {
    final parsed = parse(filename);
    return parsed?['intensity'] ?? 0;
  }

  /// Extract temperature from filename
  static int getTemperature(String filename) {
    final parsed = parse(filename);
    return parsed?['temperature'] ?? 0;
  }
}
