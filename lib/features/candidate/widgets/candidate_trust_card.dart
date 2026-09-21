import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateTrustCard extends StatelessWidget {
  final int score;
  final String userName;

  const CandidateTrustCard({
    super.key,
    required this.score,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = score == 100
        ? AppColors.success
        : (score >= 50 ? AppColors.warning : AppColors.error);

    return Container(
      height: 200,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PROFILE COMPLETENESS",
                style: AppTypography.sectionHeader.copyWith(color: Colors.white70),
              ),
              Icon(Icons.verified_user, color: scoreColor, size: 24),
            ],
          ),
          const Spacer(),
          Text(
            "$score% COMPLETE",
            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 26),
          ),
          Text(
            userName.isEmpty ? "Candidate" : userName,
            style: AppTypography.bodyMediumBold.copyWith(color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }
}

class CandidateVerificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isCompleted;

  const CandidateVerificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accentColor.withValues(alpha: 0.1),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMediumBold),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.verified : Icons.pending_outlined,
            color: isCompleted ? AppColors.success : AppColors.warning,
            size: 20,
          ),
        ],
      ),
    );
  }
}
