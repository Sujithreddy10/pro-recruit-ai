import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class OnboardingStepScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget content;
  final Widget primaryButton;
  final Widget? secondaryButton;
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingStepScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.primaryButton,
    this.secondaryButton,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          SizedBox(height: AppSpacing.md),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: AppBorderRadius.large,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary)),
          SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          SizedBox(height: AppSpacing.xl),
          Expanded(child: content),
          primaryButton,
          if (secondaryButton != null) ...[SizedBox(height: AppSpacing.sm), secondaryButton!],
        ],
      ),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

class OnboardingWelcomeStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;
  final bool isCompleting;

  const OnboardingWelcomeStep({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
    required this.isCompleting,
  });

  Widget _point(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E40AF), size: 22),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      showBack: false,
      icon: Icons.waving_hand_rounded,
      title: "Welcome to Hylo",
      subtitle: "Let's get your profile match-ready in 3 quick steps.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _point(Icons.upload_file_rounded, "Upload your resume"),
          _point(Icons.psychology_outlined, "Get an instant AI skill snapshot"),
          _point(Icons.work_outline_rounded, "See real jobs waiting for you"),
        ],
      ),
      primaryButton: OnboardingPrimaryButton(label: "Get Started", onPressed: onGetStarted),
      secondaryButton: TextButton(
        onPressed: isCompleting ? null : onSkip,
        child: Text("Skip for now", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}

class OnboardingResumeStep extends StatelessWidget {
  final bool resumeUploaded;
  final String? resumeFileName;
  final bool isUploading;
  final VoidCallback onUploadResume;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const OnboardingResumeStep({
    super.key,
    required this.resumeUploaded,
    required this.resumeFileName,
    required this.isUploading,
    required this.onUploadResume,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      onBack: onBack,
      icon: Icons.upload_file_rounded,
      title: "Upload Your Resume",
      subtitle: "We'll use this to find better matches and generate your skill snapshot.",
      content: Center(
        child: resumeUploaded
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  SizedBox(height: AppSpacing.sm),
                  Text(resumeFileName ?? "Resume uploaded", style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                ],
              )
            : Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted),
      ),
      primaryButton: resumeUploaded
          ? OnboardingPrimaryButton(label: "Continue", onPressed: onContinue)
          : OnboardingPrimaryButton(label: "Choose PDF", onPressed: onUploadResume, loading: isUploading),
      secondaryButton: TextButton(
        onPressed: onSkip,
        child: Text("Skip this step", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}

class OnboardingSkillSnapshotStep extends StatelessWidget {
  final bool resumeUploaded;
  final bool isAnalyzing;
  final Map<String, dynamic>? skillSnapshot;
  final VoidCallback onRunSnapshot;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingSkillSnapshotStep({
    super.key,
    required this.resumeUploaded,
    required this.isAnalyzing,
    required this.skillSnapshot,
    required this.onRunSnapshot,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!resumeUploaded) {
      content = Center(
        child: Text(
          "Upload a resume to unlock your AI skill snapshot.",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    } else if (isAnalyzing) {
      content = const Center(child: CircularProgressIndicator());
    } else if (skillSnapshot == null) {
      content = Center(
        child: TextButton(onPressed: onRunSnapshot, child: const Text("Analyze My Resume")),
      );
    } else {
      final score = skillSnapshot!['score'] ?? 0;
      final checks = (skillSnapshot!['checks'] as List?) ?? [];
      content = ListView(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: AppBorderRadius.large,
            ),
            child: Row(
              children: [
                Text("$score", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text("Resume Quality Score", style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ...checks.take(4).map((c) => ListTile(
                dense: true,
                leading: Icon(
                  c['passed'] == true ? Icons.check_circle : Icons.cancel,
                  color: c['passed'] == true ? AppColors.success : AppColors.textMuted,
                  size: 20,
                ),
                title: Text(c['label'] ?? '', style: AppTypography.bodySmall),
              )),
        ],
      );
    }

    return OnboardingStepScaffold(
      onBack: onBack,
      icon: Icons.psychology_outlined,
      title: "Your Skill Snapshot",
      subtitle: "A quick AI read on how your resume looks to recruiters.",
      content: content,
      primaryButton: OnboardingPrimaryButton(label: "Continue", onPressed: onContinue),
    );
  }
}

class OnboardingJobMatchesStep extends StatelessWidget {
  final bool isLoadingJobs;
  final List<Map<String, dynamic>> previewJobs;
  final bool isCompleting;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingJobMatchesStep({
    super.key,
    required this.isLoadingJobs,
    required this.previewJobs,
    required this.isCompleting,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoadingJobs) {
      content = const Center(child: CircularProgressIndicator());
    } else if (previewJobs.isEmpty) {
      content = Center(
        child: Text("No jobs available right now — check back soon.", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      );
    } else {
      content = ListView.builder(
        itemCount: previewJobs.length,
        itemBuilder: (c, i) {
          final job = previewJobs[i];
          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorderRadius.large,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                    borderRadius: AppBorderRadius.small,
                  ),
                  child: const Icon(Icons.work_outline_rounded, color: Color(0xFF1E40AF), size: 20),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title'] ?? 'Untitled Role', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                      Text(job['company'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return OnboardingStepScaffold(
      onBack: onBack,
      icon: Icons.work_outline_rounded,
      title: "Jobs Waiting For You",
      subtitle: "A preview of real openings on Hylo right now.",
      content: content,
      primaryButton: OnboardingPrimaryButton(label: "Get Started", onPressed: onComplete, loading: isCompleting),
    );
  }
}
