import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ResumeAnalysisData {
  final bool hasResume;
  final int score;
  final List<Map<String, dynamic>> checks;
  final String? errorMessage;

  ResumeAnalysisData({
    required this.hasResume,
    required this.score,
    required this.checks,
    this.errorMessage,
  });
}

class ResumeScoreHeroCard extends StatelessWidget {
  final int score;

  const ResumeScoreHeroCard({super.key, required this.score});

  Color get scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
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
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(scoreColor == AppColors.error ? Colors.orangeAccent : Colors.greenAccent),
                  ),
                ),
                Text("$score%", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RESUME ANALYSIS", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 2)),
                SizedBox(height: AppSpacing.xs),
                Text("Quality Report", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20)),
                SizedBox(height: AppSpacing.xs),
                Text("Based on your uploaded resume", style: AppTypography.caption.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResumeScoreCheckTile extends StatelessWidget {
  final Map<String, dynamic> check;

  const ResumeScoreCheckTile({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final passed = check['passed'] == true;
    final checkColor = passed ? AppColors.success : AppColors.error;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: checkColor.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: checkColor.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: checkColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(passed ? Icons.check_rounded : Icons.close_rounded, color: checkColor, size: 18),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check['label'] ?? '', style: AppTypography.bodyMediumBold),
                Text(check['detail'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(checkColor),
            child: Text(passed ? "PASS" : "MISSING", style: AppTypography.captionBold.copyWith(color: checkColor)),
          ),
        ],
      ),
    );
  }
}

class ResumeScoreJobMatchCard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? jobMatch;

  const ResumeScoreJobMatchCard({
    super.key,
    required this.loading,
    required this.jobMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, AppColors.primary.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: loading
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: AppColors.primary),
                        SizedBox(width: AppSpacing.xs),
                        Text("JOB MATCH", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    Text("${jobMatch?['matchPercent'] ?? 0}%",
                        style: AppTypography.headlineLarge.copyWith(color: AppColors.primary, fontSize: 26)),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppBorderRadius.small,
                  child: LinearProgressIndicator(
                    value: ((jobMatch?['matchPercent'] ?? 0) as int) / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text("Consider adding these keywords:", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ((jobMatch?['missingKeywords'] as List<dynamic>?) ?? [])
                      .map((kw) => Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(kw.toString(), style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }
}

class ResumeScoreEmptyPrompt extends StatelessWidget {
  const ResumeScoreEmptyPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
            SizedBox(height: AppSpacing.md),
            Text(
              "Upload a resume first to see your quality score.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
