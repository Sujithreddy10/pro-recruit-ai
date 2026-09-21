import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/features/candidate/screens/ai_interview_simulation_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/mnc_question_bank_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/pitch_analysis_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/resume_score_screen.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_growth_card.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class AIPrepTab extends StatelessWidget {
  const AIPrepTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
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
          CandidateGrowthCard(
            title: "Resume Quality / ATS Score",
            icon: Icons.analytics_outlined,
            description: "Real scoring based on your uploaded resume content.",
            accentColor: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ResumeScoreScreen()),
            ),
          ),
          CandidateGrowthCard(
            title: "Interview Question Bank",
            icon: Icons.menu_book_outlined,
            description: "Curated question sets per company, tied to your applications.",
            accentColor: AppColors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const MNCQuestionBankScreen()),
            ),
          ),
          CandidateGrowthCard(
            title: "Pitch Analysis",
            icon: Icons.mic_outlined,
            description: "Speak your pitch and get real pacing and filler-word feedback.",
            accentColor: AppColors.error,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const PitchAnalysisScreen()),
            ),
          ),
          CandidateGrowthCard(
            title: "AI Interview Simulation",
            icon: Icons.psychology_outlined,
            description: "Live mock interview rounds with real feedback.",
            accentColor: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AIInterviewSimulationScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
