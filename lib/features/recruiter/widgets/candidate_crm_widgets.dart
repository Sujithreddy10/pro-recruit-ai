import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateCrmFilterBar extends StatelessWidget {
  final String selectedFilter;
  final int totalCount;
  final Map<String, int> counts;
  final ValueChanged<String> onFilterSelected;

  const CandidateCrmFilterBar({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.counts,
    required this.onFilterSelected,
  });

  Widget _buildChip(String key, String label, int count) {
    final isSelected = selectedFilter == key;
    return GestureDetector(
      onTap: () => onFilterSelected(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        margin: EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: AppBorderRadius.small,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.captionBold.copyWith(
                color: isSelected ? AppColors.textLight : AppColors.textMuted,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: AppSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: isSelected ? AppColors.textLight : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('all', 'All', totalCount),
          _buildChip('applied', 'Applied', counts['applied'] ?? 0),
          _buildChip('shortlisted', 'Shortlisted', counts['shortlisted'] ?? 0),
          _buildChip('offer_sent', 'Offer Sent', counts['offer_sent'] ?? 0),
          _buildChip('hired', 'Hired', counts['hired'] ?? 0),
          _buildChip('rejected', 'Rejected', counts['rejected'] ?? 0),
        ],
      ),
    );
  }
}

class CandidateCrmCard extends StatelessWidget {
  final String name;
  final String? resumePath;
  final String jobTitle;
  final String companyName;
  final String status;
  final Color statusColor;
  final int rating;
  final bool isSaved;
  final VoidCallback onViewResume;
  final VoidCallback onMessage;
  final VoidCallback onEditNotesAndRating;
  final VoidCallback onToggleSave;
  final VoidCallback? onSendOffer;

  const CandidateCrmCard({
    super.key,
    required this.name,
    this.resumePath,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.statusColor,
    required this.rating,
    required this.isSaved,
    required this.onViewResume,
    required this.onMessage,
    required this.onEditNotesAndRating,
    required this.onToggleSave,
    this.onSendOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.06), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.14),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: AppTypography.bodyMediumBold.copyWith(color: statusColor),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyMediumBold),
                Text(
                  "$jobTitle @ $companyName",
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
                SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: AppDecorations.pill(statusColor),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: AppTypography.captionBold.copyWith(color: statusColor),
                  ),
                ),
                if (rating > 0) ...[
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.description_outlined, color: Colors.deepOrange, size: 16),
            onPressed: onViewResume,
            tooltip: "View Resume",
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 16),
            onPressed: onMessage,
            tooltip: 'Message Candidate',
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.rate_review_outlined, color: Colors.amber.shade800, size: 16),
            onPressed: onEditNotesAndRating,
            tooltip: 'Notes & Rating',
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.primary,
              size: 16,
            ),
            onPressed: onToggleSave,
            tooltip: 'Save Candidate',
          ),
          if (onSendOffer != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.send, color: AppColors.info, size: 20),
              onPressed: onSendOffer,
              tooltip: "Send Offer",
            ),
        ],
      ),
    );
  }
}
