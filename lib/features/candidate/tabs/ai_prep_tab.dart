import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/features/candidate/screens/ai_interview_simulation_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/mnc_question_bank_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/pitch_analysis_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/resume_score_screen.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class AIPrepTab extends StatelessWidget {
  const AIPrepTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg),
      children: [
        Text(
          "Interview Prep",
          style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
        ),
        Text(
          "These tools are in development — nothing here reflects real analysis yet.",
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: AppSpacing.xl),
        _premiumFeatureCard(
          "Resume Quality / ATS Score",
          Icons.analytics_outlined,
          "Real scoring based on your uploaded resume content.",
          Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const ResumeScoreScreen()),
          ),
        ),
        _premiumFeatureCard(
          "Interview Question Bank",
          Icons.menu_book_outlined,
          "Curated question sets per company, tied to your applications.",
          AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const MNCQuestionBankScreen()),
          ),
        ),
        _premiumFeatureCard(
          "Pitch Analysis",
          Icons.mic_outlined,
          "Speak your pitch and get real pacing and filler-word feedback.",
          AppColors.error,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PitchAnalysisScreen()),
          ),
        ),
        _premiumFeatureCard(
          "AI Interview Simulation",
          Icons.psychology_outlined,
          "Live mock interview rounds with real feedback.",
          Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AIInterviewSimulationScreen()),
          ),
        ),
      ],
    );
  }

  Widget _premiumFeatureCard(
    String title,
    IconData icon,
    String desc,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppBorderRadius.small,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    desc,
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
