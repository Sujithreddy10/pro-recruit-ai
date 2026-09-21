import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateLeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final String title;
  final int score;
  final Color accentColor;

  const CandidateLeaderboardTile({
    super.key,
    required this.rank,
    required this.name,
    required this.title,
    required this.score,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor,
            child: Text(
              "#$rank",
              style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textLight),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMediumBold),
                Text(title, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(accentColor),
            child: Text("$score shortlisted", style: AppTypography.captionBold.copyWith(color: accentColor)),
          ),
        ],
      ),
    );
  }
}
