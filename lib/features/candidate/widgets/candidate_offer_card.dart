import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateOfferCard extends StatelessWidget {
  final String role;
  final String company;
  final bool isHired;
  final String appliedOn;

  const CandidateOfferCard({
    super.key,
    required this.role,
    required this.company,
    required this.isHired,
    required this.appliedOn,
  });

  Widget _detailRow(String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label: ", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            Text(value, style: AppTypography.bodySmallBold),
          ],
        ),
      );

  void _showOfferDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Offer Details", style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Role", role),
            _detailRow("Company", company),
            _detailRow("Status", isHired ? "Hired" : "Offer Sent"),
            _detailRow("Applied On", appliedOn),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = isHired ? AppColors.success : AppColors.info;
    return GestureDetector(
      onTap: () => _showOfferDetail(context),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: c.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: AppBorderRadius.small,
              ),
              child: Icon(isHired ? Icons.check_circle : Icons.hourglass_bottom, color: c, size: 22),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    isHired ? "Hired at $company" : "Offer sent by $company",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: c),
          ],
        ),
      ),
    );
  }
}
