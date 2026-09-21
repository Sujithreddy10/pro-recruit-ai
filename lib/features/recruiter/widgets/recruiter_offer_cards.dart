import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterOfferHeader extends StatelessWidget {
  final int pendingCount;
  final int securedCount;

  const RecruiterOfferHeader({
    super.key,
    required this.pendingCount,
    required this.securedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = pendingCount + securedCount;
    final rate = total == 0 ? 0 : ((securedCount / total) * 100).round();

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF059669)]),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OFFER ACCEPTANCE: $rate%",
                  style: AppTypography.sectionHeader.copyWith(color: Colors.greenAccent),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "$securedCount Offers Secured",
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$pendingCount pending",
                  style: AppTypography.caption.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Icon(Icons.verified_user, color: AppColors.textLight, size: 40),
        ],
      ),
    );
  }
}

class RecruiterPendingOfferCard extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onMarkAccepted;

  const RecruiterPendingOfferCard({
    super.key,
    required this.name,
    required this.role,
    required this.onMarkAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withValues(alpha: 0.06), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 18),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(name, style: AppTypography.bodyMediumBold, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: AppDecorations.pill(AppColors.warning),
                child: Text("PENDING", style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF064E3B), AppColors.success]),
                borderRadius: AppBorderRadius.small,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onMarkAccepted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textLight,
                ),
                child: Text(
                  "MARK ACCEPTED",
                  style: AppTypography.captionBold.copyWith(color: AppColors.textLight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecruiterSecuredOfferTile extends StatelessWidget {
  final String name;
  final String role;

  const RecruiterSecuredOfferTile({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withValues(alpha: 0.08), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(AppColors.success),
            child: Text("HIRED", style: AppTypography.captionBold.copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}
