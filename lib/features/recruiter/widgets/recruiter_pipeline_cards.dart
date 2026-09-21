import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterPipelineHeader extends StatelessWidget {
  final int total;

  const RecruiterPipelineHeader({super.key, required this.total});

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
            "Real-time candidate status across all roles",
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

  const RecruiterPipelineStageCard({
    super.key,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.bodyMediumBold),
              Text(
                count,
                style: AppTypography.bodySmallBold.copyWith(color: accentColor),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppBorderRadius.small,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
