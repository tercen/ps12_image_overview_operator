import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/image_overview_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import 'image_detail_view.dart';

/// Grid layout for PamGene images (4 rows × N columns)
class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageOverviewProvider>(
      builder: (context, provider, _) {
        final barcodes = provider.filteredBarcodes;
        final wells = provider.filteredWells;

        if (barcodes.isEmpty || wells.isEmpty) {
          return Center(
            child: Text(
              'No images match the selected filters',
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
                return _buildImageCell(context, image);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImageCell(BuildContext context, dynamic image) {
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
        child: const Center(
          child: Text('—'),
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
        child: FutureBuilder<Uint8List>(
          future: rootBundle.load(image.imagePath!).then((data) => data.buffer.asUint8List()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Icon(Icons.broken_image, size: 32),
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
