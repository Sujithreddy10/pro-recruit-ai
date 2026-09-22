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

class NotesAndRatingDialog extends StatefulWidget {
  final String? initialNotes;
  final int? initialRating;
  final void Function(String notes, int? rating) onSave;

  const NotesAndRatingDialog({
    super.key,
    this.initialNotes,
    this.initialRating,
    required this.onSave,
  });

  @override
  State<NotesAndRatingDialog> createState() => _NotesAndRatingDialogState();
}

class _NotesAndRatingDialogState extends State<NotesAndRatingDialog> {
  late final TextEditingController _notesCtrl;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');
    _rating = widget.initialRating ?? 0;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      title: Text("Notes & Rating", style: AppTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rating", style: AppTypography.bodySmallBold),
            SizedBox(height: AppSpacing.xs),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Private Notes",
                hintText: "Only visible to your recruiting team",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSave(
              _notesCtrl.text.trim(),
              _rating == 0 ? null : _rating,
            );
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

Color getCandidateStatusColor(String status) {
  switch (status) {
    case 'shortlisted':
      return AppColors.success;
    case 'offer_sent':
      return AppColors.info;
    case 'hired':
      return Colors.teal;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

class CandidateCrmSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const CandidateCrmSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: "Search candidates, roles...",
            prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class CandidateCrmEmptyView extends StatelessWidget {
  const CandidateCrmEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_off_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
          SizedBox(height: AppSpacing.sm),
          Text(
            "No candidates found.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class CandidateCrmListView extends StatelessWidget {
  final List<Map<String, dynamic>> candidates;
  final Set<String> savedCandidateIds;
  final void Function(String? resumePath) onViewResume;
  final void Function(String candidateId, String name, String jobTitle, String companyName) onMessage;
  final void Function(Map<String, dynamic> candidate) onEditNotesAndRating;
  final void Function(String candidateId) onToggleSave;
  final void Function(int applicationId) onSendOffer;

  const CandidateCrmListView({
    super.key,
    required this.candidates,
    required this.savedCandidateIds,
    required this.onViewResume,
    required this.onMessage,
    required this.onEditNotesAndRating,
    required this.onToggleSave,
    required this.onSendOffer,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const CandidateCrmEmptyView();
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemCount: candidates.length,
      itemBuilder: (context, i) {
        final c = candidates[i];
        final profile = c['profiles'];
        final name = profile?['full_name'] ?? 'Unknown Candidate';
        final resumePath = profile?['resume_path'];
        final status = (c['status'] ?? 'applied').toString();
        final color = getCandidateStatusColor(status);
        final profileId = (profile?['id'] ?? '').toString();

        return CandidateCrmCard(
          name: name,
          resumePath: resumePath,
          jobTitle: (c['job_title'] ?? 'N/A').toString(),
          companyName: (c['company_name'] ?? 'N/A').toString(),
          status: status,
          statusColor: color,
          rating: (c['recruiter_rating'] as int?) ?? 0,
          isSaved: savedCandidateIds.contains(profileId),
          onViewResume: () => onViewResume(resumePath),
          onMessage: () => onMessage(
            profileId,
            name,
            (c['job_title'] ?? '').toString(),
            (c['company_name'] ?? '').toString(),
          ),
          onEditNotesAndRating: () => onEditNotesAndRating(c),
          onToggleSave: () => onToggleSave(profileId),
          onSendOffer: status == 'shortlisted' ? () => onSendOffer(c['id']) : null,
        );
      },
    );
  }
}
