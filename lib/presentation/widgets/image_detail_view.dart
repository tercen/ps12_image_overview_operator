import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/models/image_metadata.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';

/// Detail view with zoom and pan for full-size image
class ImageDetailView extends StatefulWidget {
  final ImageMetadata image;

  const ImageDetailView({super.key, required this.image});

  @override
  State<ImageDetailView> createState() => _ImageDetailViewState();
}

class _ImageDetailViewState extends State<ImageDetailView> {
  final TransformationController _transformationController = TransformationController();
  double _scale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.5).clamp(1.0, 10.0);
      _transformationController.value = Matrix4.identity()..scale(_scale);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.5).clamp(1.0, 10.0);
      _transformationController.value = Matrix4.identity()..scale(_scale);
    });
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
      appBar: AppBar(
        title: Text(widget.image.filename),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlassMinus),
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlassPlus),
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Image viewer
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 10.0,
              onInteractionUpdate: (details) {
                setState(() {
                  _scale = _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Center(
                child: FutureBuilder<Uint8List>(
                  future: rootBundle.load(widget.image.imagePath!).then((data) => data.buffer.asUint8List()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Icon(Icons.broken_image, size: 64);
                    }

                    return Image.memory(snapshot.data!);
                  },
                ),
              ),
            ),
          ),

          // Metadata panel
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: isDark ? AppColorsDark.surface : AppColors.surface,
              border: Border(
                left: BorderSide(
                  color: isDark ? AppColorsDark.border : AppColors.border,
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'METADATA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetadataRow(context, 'Filename', widget.image.filename),
                _buildMetadataRow(context, 'Barcode', widget.image.barcode),
                _buildMetadataRow(context, 'Well', 'W${widget.image.well}'),
                _buildMetadataRow(context, 'Field', 'F${widget.image.field}'),
                _buildMetadataRow(context, 'Cycle', 'P${widget.image.cycle}'),
                _buildMetadataRow(context, 'Exposure Time', '${widget.image.exposureTime}ms'),
                if (widget.image.temperature != null)
                  _buildMetadataRow(context, 'Temperature', 'T${widget.image.temperature}'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Zoom: ${_scale.toStringAsFixed(1)}x',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
