import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateRecruiterCard extends StatelessWidget {
  final String name;
  final String role;
  final Color accentColor;
  final VoidCallback onReferralRequested;

  const CandidateRecruiterCard({
    super.key,
    required this.name,
    required this.role,
    required this.accentColor,
    required this.onReferralRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: AppTypography.bodyMediumBold.copyWith(color: accentColor),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMediumBold),
                Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: accentColor.withValues(alpha: 0.1)),
            onPressed: onReferralRequested,
            child: Text("REFER ME", style: AppTypography.captionBold.copyWith(color: accentColor)),
          )
        ],
      ),
    );
  }
}
