import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterConsoleSnapshotCard extends StatelessWidget {
  final Future<Map<String, int>> pipelineCountsFuture;
  final ValueChanged<int>? onNavigateToTab;

  const RecruiterConsoleSnapshotCard({
    super.key,
    required this.pipelineCountsFuture,
    this.onNavigateToTab,
  });

  Widget _snapshotStat(
    String value,
    String label,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.headlineLarge.copyWith(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, int>>(
      future: pipelineCountsFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'applied': 0, 'shortlisted': 0, 'rejected': 0};

        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: AppBorderRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "PIPELINE SNAPSHOT",
                    style: AppTypography.sectionHeader.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              snapshot.connectionState == ConnectionState.waiting
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _snapshotStat(
                          "${counts['applied']}",
                          "Applied",
                          AppColors.info,
                          isDark,
                          () => onNavigateToTab?.call(2),
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                        ),
                        _snapshotStat(
                          "${counts['shortlisted']}",
                          "Shortlisted",
                          AppColors.success,
                          isDark,
                          () => onNavigateToTab?.call(2),
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                        ),
                        _snapshotStat(
                          "${counts['rejected']}",
                          "Rejected",
                          AppColors.error,
                          isDark,
                          () => onNavigateToTab?.call(2),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class RecruiterConsoleNavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap;

  const RecruiterConsoleNavTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.large,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: AppBorderRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMediumBold.copyWith(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionBold.copyWith(
                      color: color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
