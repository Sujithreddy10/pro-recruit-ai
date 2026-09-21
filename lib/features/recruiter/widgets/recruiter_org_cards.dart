import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterOrgHeader extends StatelessWidget {
  final int totalUsers;

  const RecruiterOrgHeader({super.key, required this.totalUsers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PLATFORM OVERVIEW",
            style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            "$totalUsers Total Users",
            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
          ),
          Text(
            "Live counts from your Supabase backend",
            style: AppTypography.caption.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class RecruiterOrgStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;

  const RecruiterOrgStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
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
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTypography.bodyMediumBold)),
          Text("$count", style: AppTypography.titleMedium.copyWith(color: accentColor)),
        ],
      ),
    );
  }
}
