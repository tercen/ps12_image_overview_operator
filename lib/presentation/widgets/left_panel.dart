import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/image_overview_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/version/version_info.dart';

/// Left panel with filters and controls
class LeftPanel extends StatefulWidget {
  const LeftPanel({super.key});

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = AppSpacing.panelWidth;  // Resizable: 280-400px
  bool _isCollapsed = false;
  bool _isResizing = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'filters': GlobalKey(),
    'info': GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isCollapsed ? AppSpacing.panelCollapsedWidth : _panelWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surface : AppColors.surface,
      ),
      child: Stack(
        children: [
          // Main panel content
          Column(
        children: [
          // Header
          _buildHeader(context, primaryColor),

          // Content (expanded) or Icon Strip (collapsed)
          Expanded(
            child: _isCollapsed
                ? _buildCollapsedIconStrip(context, isDark, primaryColor)
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          key: _sectionKeys['filters'],
                          context: context,
                          isDark: isDark,
                          icon: FontAwesomeIcons.filter,
                          label: 'FILTERS',
                          content: _buildFilterContent(context, isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection(
                          key: _sectionKeys['info'],
                          context: context,
                          isDark: isDark,
                          icon: FontAwesomeIcons.circleInfo,
                          label: 'INFO',
                          content: _buildInfoContent(context, isDark),
                        ),
                      ],
                    ),
                  ),
          ),

          // Footer (chevron when collapsed)
          if (_isCollapsed) _buildCollapsedFooter(context, primaryColor),
        ],
      ),

          // Resize handle (only when expanded)
          if (!_isCollapsed) _buildResizeHandle(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    if (_isCollapsed) {
      // Collapsed: only app icon (centered, clickable to expand)
      return GestureDetector(
        onTap: () {
          setState(() {
            _isCollapsed = false;
          });
        },
        child: Container(
          height: AppSpacing.headerHeight,
          decoration: BoxDecoration(
            color: primaryColor,
          ),
          child: const Center(
            child: Icon(
              FontAwesomeIcons.microscope,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Expanded: icon, title, theme toggle, collapse chevron
    return Container(
      height: AppSpacing.headerHeight,
      decoration: BoxDecoration(
        color: primaryColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.microscope,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PS12 Image Overview',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Theme toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? FontAwesomeIcons.sun
                      : FontAwesomeIcons.moon,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              );
            },
          ),
          // Collapse chevron
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.chevronLeft,
              size: 14,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isCollapsed = true;
              });
            },
            tooltip: 'Collapse',
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedIconStrip(BuildContext context, bool isDark, Color primaryColor) {
    final iconColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return Column(
      children: [
        // Section icons
        IconButton(
          icon: Icon(FontAwesomeIcons.filter, size: 20, color: iconColor),
          onPressed: () => _onSectionIconTap('filters'),
          tooltip: 'Filters',
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.circleInfo, size: 20, color: iconColor),
          onPressed: () => _onSectionIconTap('info'),
          tooltip: 'Info',
        ),
      ],
    );
  }

  void _onSectionIconTap(String sectionId) {
    if (_isCollapsed) {
      setState(() {
        _isCollapsed = false;
      });

      // Wait for expansion animation to complete, then scroll to section
      Future.delayed(const Duration(milliseconds: 200), () {
        final context = _sectionKeys[sectionId]?.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Widget _buildCollapsedFooter(BuildContext context, Color primaryColor) {
    return Container(
      height: AppSpacing.headerHeight,
      decoration: BoxDecoration(
        color: primaryColor,
      ),
      child: Center(
        child: IconButton(
          icon: const Icon(
            FontAwesomeIcons.chevronRight,
            size: 14,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isCollapsed = false;
            });
          },
          tooltip: 'Expand',
        ),
      ),
    );
  }

  Widget _buildResizeHandle(BuildContext context, bool isDark) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          setState(() {
            _isResizing = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            // Update panel width based on drag delta
            final newWidth = _panelWidth + details.delta.dx;
            // Clamp between min (280px) and max (400px)
            _panelWidth = newWidth.clamp(AppSpacing.panelMinWidth, AppSpacing.panelMaxWidth);
          });
        },
        onHorizontalDragEnd: (details) {
          setState(() {
            _isResizing = false;
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _isResizing
                      ? (isDark ? AppColorsDark.primary : AppColors.primary)
                      : (isDark ? AppColorsDark.border : AppColors.border),
                  width: _isResizing ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required GlobalKey? key,
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Container(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Section content
          content,
        ],
      ),
    );
  }

  Widget _buildFilterContent(BuildContext context, bool isDark) {
    return Consumer<ImageOverviewProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle filter
            Text(
              'Cycle',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<int>(
              value: provider.selectedCycle,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: provider.availableCycles.map((cycle) {
                return DropdownMenuItem(
                  value: cycle,
                  child: Text('P$cycle'),
                );
              }).toList(),
              onChanged: (value) {
                provider.setCycle(value);
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Exposure Time filter
            Text(
              'Exposure Time',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<int>(
              value: provider.selectedExposureTime,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: provider.availableExposureTimes.map((exposure) {
                return DropdownMenuItem(
                  value: exposure,
                  child: Text('${exposure}ms'),
                );
              }).toList(),
              onChanged: (value) {
                provider.setExposureTime(value);
              },
            ),

          ],
        );
      },
    );
  }

  Widget _buildInfoContent(BuildContext context, bool isDark) {
    return Consumer<ImageOverviewProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images count line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'Images:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${provider.filteredImages.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // GitHub line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
            children: [
              Text(
                'GitHub:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: VersionInfo.gitVersion.isNotEmpty
                    ? InkWell(
                        onTap: () => launchUrl(Uri.parse(VersionInfo.gitRepo)),
                        child: Text(
                          VersionInfo.gitVersion,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      )
                    : Text(
                        'Development',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
                            ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
      },
    );
  }
}
