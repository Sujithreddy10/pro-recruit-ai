import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterDecisionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const RecruiterDecisionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTypography.bodySmallBold.copyWith(color: AppColors.textLight)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textLight,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      ),
    );
  }
}

class RecruiterSwipeDecisionCard extends StatelessWidget {
  final String name;
  final String role;
  final String companyName;
  final String status;
  final String createdAt;
  final Color accentColor;
  final VoidCallback onViewResume;
  final VoidCallback onReject;
  final VoidCallback onHire;

  const RecruiterSwipeDecisionCard({
    super.key,
    required this.name,
    required this.role,
    required this.companyName,
    required this.status,
    required this.createdAt,
    required this.accentColor,
    required this.onViewResume,
    required this.onReject,
    required this.onHire,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.elevatedCard,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: AppBorderRadius.topLarge,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.titleMedium),
                      Text(
                        "$role @ $companyName",
                        style: AppTypography.bodySmallBold.copyWith(color: accentColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("APPLICATION STATUS", style: AppTypography.sectionHeader),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        status.toUpperCase(),
                        style: AppTypography.bodySmallBold.copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text("APPLIED ON", style: AppTypography.sectionHeader),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    createdAt.split('T').first,
                    style: AppTypography.bodyMedium,
                  ),
                  SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onViewResume,
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: Text("VIEW RESUME", style: AppTypography.bodySmallBold),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: RecruiterDecisionButton(
                    icon: Icons.close,
                    label: "REJECT",
                    color: AppColors.error,
                    onPressed: onReject,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: RecruiterDecisionButton(
                    icon: Icons.check,
                    label: "HIRE",
                    color: AppColors.success,
                    onPressed: onHire,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
