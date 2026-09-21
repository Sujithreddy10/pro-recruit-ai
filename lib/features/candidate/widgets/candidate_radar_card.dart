import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateRadarCard extends StatelessWidget {
  final Future<Map<String, dynamic>> performanceFuture;

  const CandidateRadarCard({super.key, required this.performanceFuture});

  Widget _insightStat(String val, String label, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          SizedBox(height: AppSpacing.xs),
          Text(val, style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight)),
          Text(label, style: AppTypography.caption.copyWith(color: Colors.white70)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: performanceFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'applied_count': 0, 'profile_score': 0};
        final appliedCount = data['applied_count'] as int;
        final profileScore = data['profile_score'] as int;

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
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "YOUR ACTIVITY",
                    style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 1.6),
                  ),
                  const Icon(Icons.query_stats, color: Colors.white54, size: 20),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _insightStat("$appliedCount", "Applications Sent", Icons.search),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),
              Row(
                children: [
                  Text("Profile Strength: $profileScore%", style: AppTypography.caption.copyWith(color: Colors.white70)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const CandidateProfileHub()),
                    ),
                    child: Text("IMPROVE >", style: AppTypography.captionBold.copyWith(color: AppColors.accentAmber)),
                  )
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppBorderRadius.small,
                child: LinearProgressIndicator(
                  value: profileScore / 100,
                  backgroundColor: Colors.white12,
                  color: Colors.greenAccent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
