# PS12 Image Overview

View-only QC operator for visual inspection of PS12 kinase assay fluorescence images.

## Description

A Flutter web application for quality control inspection of PamStation 12 (PS12) fluorescence microscopy images. Operators use this tool to visually review images for quality issues before downstream analysis.

## Features

- **Grid Layout**: Images organized by Well (W1-W4) and Barcode
- **Filtering**: Filter images by Cycle and Exposure Time
- **Detail View**: Click-to-enlarge with zoom and pan controls
- **Metadata Display**: View complete image metadata
- **Dark Mode**: Full light and dark theme support
- **View-Only**: No QC flagging or data output to Tercen

## Usage

### Filters

- **Cycle**: Pump cycle number (defaults to latest cycle)
- **Exposure Time**: Camera exposure in milliseconds (defaults to longest exposure)

### Grid

- Rows: Wells (W1, W2, W3, W4)
- Columns: Unique Barcodes (sorted alphanumerically)
- Click any image to open detail view

### Detail View

- **Zoom In/Out**: Use toolbar buttons or InteractiveViewer gestures
- **Pan**: Drag to navigate zoomed image
- **Reset**: Return to original zoom level
- **Metadata**: View complete image metadata in right panel

## Technical Details

### Data Format

- **Input**: PamGene TIFF images (16-bit grayscale)
- **Processing**: Automatic conversion to 8-bit PNG for web display
- **Metadata**: Extracted from TIFF EXIF tags and filename parsing

### Filename Convention

```
{barcode}_W{well}_F{field}_T{temperature}_P{cycle}_I{exposure}_A{array}.tif
```

Example: `641070616_W1_F1_T100_P94_I493_A30.tif`

## Architecture

- **Framework**: Flutter 3.38.3
- **Build Target**: WebAssembly (WASM)
- **State Management**: Provider
- **Dependency Injection**: GetIt
- **Design System**: Tercen UI standards (Material Design 3)

## Development

### Prerequisites

- Flutter SDK 3.38.3 or later
- Dart 3.10.1 or later

### Build

```bash
# Build for web with WASM
flutter build web --wasm

# Run locally
flutter run -d chrome
```

### Project Structure

```
lib/
├── core/theme/          # Design system (colors, spacing, themes)
├── di/                  # Dependency injection
├── domain/              # Abstract interfaces and models
├── implementations/     # Concrete implementations (mock, real)
├── presentation/        # UI layer (screens, widgets, providers)
└── utils/               # Utilities (TIFF converter, filename parser)
```

## References

- **Functional Specification**: IMAGE_OVERVIEW_FUNCTIONAL_SPECIFICATION_V2.0.md
- **PamGene**: www.pamgene.com
- **Tercen**: www.tercen.com

## Version History

### 1.0.0 (2026-02-02)
- Initial release
- Grid layout with filters
- Detail view with zoom/pan
- TIFF to PNG conversion
- Light and dark themes
- Mock data implementation

## License

Copyright © 2026 Tercen. All rights reserved.
