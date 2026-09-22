import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class JobAnalyticsDialog extends StatelessWidget {
  final String title;
  final int views;
  final int applications;

  const JobAnalyticsDialog({
    super.key,
    required this.title,
    required this.views,
    required this.applications,
  });

  Widget _analyticsRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepOrange),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.bodyMediumBold),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasViews = views > 0 && applications <= views;
    final conversion = hasViews ? (applications / views * 100) : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      title: Text(title, style: AppTypography.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _analyticsRow(Icons.visibility_outlined, "Views", "$views"),
          SizedBox(height: AppSpacing.sm),
          _analyticsRow(Icons.people_outline, "Applications", "$applications"),
          SizedBox(height: AppSpacing.sm),
          _analyticsRow(
            Icons.trending_up,
            "Conversion Rate",
            hasViews ? "${conversion!.toStringAsFixed(1)}%" : "N/A",
          ),
          if (!hasViews) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              "View tracking started recently — older applications may predate it.",
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}

class JobBoardHeader extends StatelessWidget {
  final int jobCount;

  const JobBoardHeader({super.key, required this.jobCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C2D12), Colors.deepOrange]),
        borderRadius: AppBorderRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "JOB BOARD MANAGEMENT",
            style: AppTypography.sectionHeader.copyWith(color: Colors.orange.shade100),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            "$jobCount Active Postings",
            style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18),
          ),
          Text(
            "Manage all open roles from one place",
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class JobBoardCard extends StatelessWidget {
  final String title;
  final String company;
  final String mode;
  final String? description;
  final String salaryRange;
  final VoidCallback onAnalytics;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JobBoardCard({
    super.key,
    required this.title,
    required this.company,
    required this.mode,
    this.description,
    required this.salaryRange,
    required this.onAnalytics,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
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
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.small,
                ),
                child: const Icon(Icons.business_center_outlined, color: Colors.deepOrange, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMediumBold),
                    Text(company, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: AppDecorations.pill(Colors.deepOrange),
                child: Text(mode, style: AppTypography.captionBold.copyWith(color: Colors.deepOrange)),
              ),
            ],
          ),
          if ((description ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text(description!, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.small,
                ),
                child: Text(
                  salaryRange,
                  style: AppTypography.bodySmallBold.copyWith(color: AppColors.success),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.bar_chart_outlined, color: Colors.deepOrange, size: 16),
                    onPressed: onAnalytics,
                    tooltip: "Analytics",
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.edit_outlined, color: AppColors.info, size: 16),
                    onPressed: onEdit,
                    tooltip: "Edit",
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                    onPressed: onDelete,
                    tooltip: "Delete",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
