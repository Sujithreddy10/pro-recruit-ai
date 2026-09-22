import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class SkillReadinessHeroCard extends StatelessWidget {
  final int readinessPercent;

  const SkillReadinessHeroCard({super.key, required this.readinessPercent});

  Color get _readinessColor {
    if (readinessPercent >= 70) return AppColors.success;
    if (readinessPercent >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: readinessPercent / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(
                      _readinessColor == AppColors.error ? Colors.orangeAccent : Colors.greenAccent,
                    ),
                  ),
                ),
                Text(
                  "$readinessPercent%",
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SKILL READINESS", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 2)),
                SizedBox(height: AppSpacing.xs),
                Text("Based on your skills + resume", style: AppTypography.caption.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkillTargetJobDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final Map<String, dynamic>? selectedJob;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const SkillTargetJobDropdown({
    super.key,
    required this.jobs,
    required this.selectedJob,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDecorations.card(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          value: selectedJob,
          icon: Icon(Icons.expand_more, color: AppColors.primary),
          items: jobs
              .map((j) => DropdownMenuItem(
                    value: j,
                    child: Text(
                      "${j['title']} @ ${j['company']}",
                      style: AppTypography.bodyMediumBold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class MatchedSkillsWrap extends StatelessWidget {
  final List<String> matchedKeywords;

  const MatchedSkillsWrap({super.key, required this.matchedKeywords});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SKILLS YOU ALREADY HAVE", style: AppTypography.sectionHeader),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: matchedKeywords
              .map((k) => Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: AppDecorations.pill(AppColors.success),
                    child: Text(k, style: AppTypography.captionBold.copyWith(color: AppColors.success)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class SkillGapItemCard extends StatelessWidget {
  final Map<String, String> gap;

  const SkillGapItemCard({super.key, required this.gap});

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(Icons.priority_high_rounded, color: AppColors.warning, size: 16),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                (gap['skill'] ?? '').toUpperCase(),
                style: AppTypography.bodyMediumBold.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          if ((gap['reason'] ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(gap['reason']!, style: AppTypography.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}

class SkillGapEmptyCard extends StatelessWidget {
  const SkillGapEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Text(
        "No gaps found for this role — nice work!",
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
