import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_overview_provider.dart';
import '../widgets/left_panel.dart';
import '../widgets/top_bar.dart';
import '../widgets/image_grid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../di/service_locator.dart';
import '../../utils/tercen_url_parser.dart';

/// Main screen for PS12 Image Overview
class ImageOverviewScreen extends StatefulWidget {
  const ImageOverviewScreen({super.key});

  @override
  State<ImageOverviewScreen> createState() => _ImageOverviewScreenState();
}

class _ImageOverviewScreenState extends State<ImageOverviewScreen> {
  late bool _showTopBar;

  @override
  void initState() {
    super.initState();
    // Check if running in Data Step or full screen mode
    // Use TercenUrlParser for consistent context detection
    final urlParser = getIt<TercenUrlParser>();
    _showTopBar = urlParser.shouldShowTopBar;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Left Panel
          const LeftPanel(),

          // Main Panel (Top Bar + Content)
          Expanded(
            child: Column(
              children: [
                // Top Bar (only in full screen mode)
                if (_showTopBar) const TopBar(),

                // Main Content Area
                Expanded(
                  child: Container(
                    color: isDark ? AppColorsDark.background : AppColors.background,
                    child: Consumer<ImageOverviewProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            provider.loadingMessage ?? 'Loading...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: isDark ? AppColorsDark.red : AppColors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage ?? 'An error occurred',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.loadImages(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return const ImageGrid();
                },
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
