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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  "LIVE PIPELINE",
                  style: AppTypography.caption.copyWith(
                    color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            "Total Applications: $total",
            style: AppTypography.headlineLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 12,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
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
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: AppTypography.bodyMediumBold.copyWith(
                            color: isDark ? const Color(0xFFF1F5F9) : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            count,
                            style: AppTypography.bodySmallBold.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                        ),
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
                    backgroundColor: isDark ? const Color(0xFF0F172A) : accentColor.withValues(alpha: 0.14),
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
