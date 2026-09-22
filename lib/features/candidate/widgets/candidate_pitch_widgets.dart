import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class PitchHeaderBanner extends StatelessWidget {
  const PitchHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF7F1D1D), AppColors.error]),
        borderRadius: AppBorderRadius.large,
        boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("REAL-TIME SPEECH ANALYSIS", style: AppTypography.sectionHeader.copyWith(color: Colors.red.shade100, letterSpacing: 1.6)),
          SizedBox(height: AppSpacing.xs),
          Text("Speak your pitch out loud", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 16)),
          Text(
            "Real pace and filler-word tracking \u2014 no fabricated scores.",
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class PitchRecordingControl extends StatelessWidget {
  final bool isListening;
  final String formattedDuration;
  final VoidCallback onTap;

  const PitchRecordingControl({
    super.key,
    required this.isListening,
    required this.formattedDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(formattedDuration, style: AppTypography.headlineLarge.copyWith(fontSize: 32)),
          SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [AppColors.error, const Color(0xFF7F1D1D)]
                      : [AppColors.success, const Color(0xFF064E3B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? AppColors.error : AppColors.success).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            isListening ? "Listening... tap to stop" : "Tap to start speaking",
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class PitchStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const PitchStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineLarge.copyWith(color: color, fontSize: 24)),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class PitchPaceCard extends StatelessWidget {
  final String paceLabel;
  final Color paceColor;

  const PitchPaceCard({
    super.key,
    required this.paceLabel,
    required this.paceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Icon(Icons.speed, color: paceColor),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paceLabel, style: AppTypography.bodyMediumBold.copyWith(color: paceColor)),
                Text(
                  "Ideal conversational pace is 110\u2013160 words per minute.",
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PitchFillerWordsCard extends StatelessWidget {
  final int totalFillers;
  final double fillerRate;
  final Map<String, int> fillerCounts;

  const PitchFillerWordsCard({
    super.key,
    required this.totalFillers,
    required this.fillerRate,
    required this.fillerCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: AppColors.warning),
              SizedBox(width: AppSpacing.sm),
              Text("Filler Words: $totalFillers", style: AppTypography.bodyMediumBold),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            "${fillerRate.toStringAsFixed(1)}% of your words were fillers",
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          if (fillerCounts.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: fillerCounts.entries
                  .map((e) => Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: AppDecorations.pill(AppColors.warning),
                        child: Text('"${e.key}" x${e.value}',
                            style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class PitchTranscriptCard extends StatelessWidget {
  final String transcript;

  const PitchTranscriptCard({super.key, required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Text(transcript.isEmpty ? "No speech detected." : transcript, style: AppTypography.bodyMedium),
    );
  }
}
