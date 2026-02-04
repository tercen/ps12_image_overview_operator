import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/image_overview_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../domain/models/image_metadata.dart';
import 'image_detail_view.dart';

/// Grid layout for PamGene images (4 rows × N columns)
///
/// Grid structure is determined by ALL images (all barcodes × all wells).
/// Individual cells show images if available for current filter, or placeholders.
class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageOverviewProvider>(
      builder: (context, provider, _) {
        // Use ALL barcodes/wells for grid structure (not filtered)
        final barcodes = provider.allBarcodes;
        final wells = provider.allWells;

        if (barcodes.isEmpty || wells.isEmpty) {
          return Center(
            child: Text(
              'No images available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _buildGridTable(context, provider, barcodes, wells),
        );
      },
    );
  }

  Widget _buildGridTable(
    BuildContext context,
    ImageOverviewProvider provider,
    List<String> barcodes,
    List<int> wells,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDark ? AppColorsDark.surfaceElevated : AppColors.surfaceElevated;
    const cellGap = 4.0; // 4px equal gaps

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top-left corner (empty)
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: headerBgColor,
                border: Border.all(color: isDark ? AppColorsDark.border : AppColors.border),
              ),
              alignment: Alignment.center,
            ),
            // Gap after corner
            const SizedBox(width: cellGap),
            // Barcode headers
            ...List.generate(barcodes.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Gap between columns
                return const SizedBox(width: cellGap);
              }
              final barcodeIndex = index ~/ 2;
              final barcode = barcodes[barcodeIndex];
              return Container(
                width: 270,
                height: 40,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  border: Border.all(color: isDark ? AppColorsDark.border : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  barcode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }),
          ],
        ),

        // Gap after header row
        const SizedBox(height: cellGap),

        // Data rows (one per well)
        ...List.generate(wells.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Gap between rows
            return const SizedBox(height: cellGap);
          }
          final wellIndex = index ~/ 2;
          final well = wells[wellIndex];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Well row header
              Container(
                width: 60,
                height: 200,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  border: Border.all(color: isDark ? AppColorsDark.border : AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'W$well',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              // Gap after well header
              const SizedBox(width: cellGap),
              // Image cells
              ...List.generate(barcodes.length * 2 - 1, (cellIndex) {
                if (cellIndex.isOdd) {
                  // Gap between columns
                  return const SizedBox(width: cellGap);
                }
                final barcodeIndex = cellIndex ~/ 2;
                final barcode = barcodes[barcodeIndex];
                final image = provider.getImageAt(barcode, well);
                return _buildImageCell(context, provider, image);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImageCell(
    BuildContext context,
    ImageOverviewProvider provider,
    ImageMetadata? image,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;

    if (image == null) {
      return Container(
        width: 270,
        height: 200,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.image,
                size: 28,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 8),
              Text(
                'No image available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImageDetailView(image: image),
          ),
        );
      },
      child: Container(
        width: 270,
        height: 200,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: FutureBuilder<Uint8List?>(
          future: provider.fetchAndConvertImage(image.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Center(
                child: FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 28,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              );
            }

            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}
