import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterPipelineHeader extends StatelessWidget {
  final int total;
  final String subtitle;

  const RecruiterPipelineHeader({
    super.key,
    required this.total,
    this.subtitle = "Real-time candidate status across all roles",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LIVE PIPELINE",
            style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            "Total Applications: $total",
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textLight,
              fontSize: 18,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class RecruiterPipelineStageCard extends StatelessWidget {
  final String title;
  final String count;
  final Color accentColor;
  final double progress;
  final VoidCallback? onTap;

  const RecruiterPipelineStageCard({
    super.key,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.medium,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(title, style: AppTypography.bodyMediumBold),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          count,
                          style: AppTypography.bodySmallBold.copyWith(color: accentColor),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppBorderRadius.small,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
