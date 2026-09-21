import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateJobCard extends StatelessWidget {
  final String id;
  final String recruiterId;
  final String title;
  final String company;
  final String mode;
  final String description;
  final String? location;
  final String? logoUrl;
  final Color accent;
  final bool isSaved;
  final bool isApplied;
  final VoidCallback onToggleSave;
  final VoidCallback onStartConversation;
  final VoidCallback onApply;

  const CandidateJobCard({
    super.key,
    required this.id,
    required this.recruiterId,
    required this.title,
    required this.company,
    required this.mode,
    required this.description,
    required this.accent,
    required this.isSaved,
    required this.isApplied,
    required this.onToggleSave,
    required this.onStartConversation,
    required this.onApply,
    this.location,
    this.logoUrl,
  });

  Widget _badge(String label, Color accent) => Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: AppDecorations.pill(accent),
        child: Text(label, style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.large,
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]),
                  borderRadius: AppBorderRadius.small,
                ),
                child: (logoUrl != null && logoUrl!.isNotEmpty)
                    ? Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(Icons.business_rounded, color: accent, size: 24),
                      )
                    : Icon(Icons.business_rounded, color: accent, size: 24),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    Text(company, style: AppTypography.bodySmallBold.copyWith(color: accent)),
                    if (location != null && location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                location!,
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _badge(mode, accent),
              IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: accent, size: 20),
                onPressed: onToggleSave,
                tooltip: isSaved ? 'Unsave' : 'Save job',
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: accent, size: 20),
                onPressed: onStartConversation,
                tooltip: 'Message Recruiter',
              ),
            ],
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.border)),
          Text(description, style: AppTypography.bodyMedium),
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: isApplied
                  ? null
                  : BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryDark, accent]),
                      borderRadius: AppBorderRadius.small,
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
              child: TextButton(
                onPressed: isApplied ? null : onApply,
                style: TextButton.styleFrom(
                  backgroundColor: isApplied ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                ),
                child: Text(
                  isApplied ? "Applied ✓" : "Apply Now",
                  style: AppTypography.bodySmallBold.copyWith(color: isApplied ? AppColors.success : AppColors.textLight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
