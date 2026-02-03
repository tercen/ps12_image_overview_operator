import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';

/// Top bar shown in full screen mode
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: AppSpacing.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColorsDark.border : AppColors.border,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Context badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColorsDark.primarySurface : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'FULL SCREEN MODE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? AppColorsDark.primary : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          const Spacer(),

          // Close button (visual only for mock - users can close tab/window)
          IconButton(
            icon: Icon(
              FontAwesomeIcons.xmark,
              size: 16,
              color: isDark ? AppColorsDark.textMuted : AppColors.textMuted,
            ),
            onPressed: () {
              // In production, this would close the window
              // For mock: users close the tab/window themselves
            },
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
