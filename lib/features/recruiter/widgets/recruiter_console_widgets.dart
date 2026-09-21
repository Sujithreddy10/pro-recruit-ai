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

  Widget _snapshotStat(String value, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: AppTypography.headlineLarge.copyWith(color: color, fontSize: 20)),
            SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: pipelineCountsFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'applied': 0, 'shortlisted': 0, 'rejected': 0};
        return Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.elevatedCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text("PIPELINE SNAPSHOT", style: AppTypography.sectionHeader),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _snapshotStat("${counts['applied']}", "Applied", AppColors.info,
                            () => onNavigateToTab?.call(2)),
                        _snapshotStat("${counts['shortlisted']}", "Shortlisted", AppColors.success,
                            () => onNavigateToTab?.call(2)),
                        _snapshotStat("${counts['rejected']}", "Rejected", AppColors.error,
                            () => onNavigateToTab?.call(2)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMediumBold),
                Text(subtitle, style: AppTypography.captionBold.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
