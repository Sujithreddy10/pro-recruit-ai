import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class TrustIDTab extends StatefulWidget {
  const TrustIDTab({super.key});

  @override
  State<TrustIDTab> createState() => _TrustIDTabState();
}

class _TrustIDTabState extends State<TrustIDTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<Map<String, dynamic>> _fetchMyTrustData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'full_name': '', 'resume_path': null};

    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name, resume_path')
        .eq('id', userId)
        .maybeSingle();

    return data ?? {'full_name': '', 'resume_path': null};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMyTrustData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final profile = snapshot.data ?? {};
        final hasName = (profile['full_name'] ?? '').toString().isNotEmpty;
        final hasResume = (profile['resume_path'] ?? '').toString().isNotEmpty;
        final checks = [
          {'label': 'Profile Name Set', 'passed': hasName},
          {'label': 'Resume Uploaded', 'passed': hasResume},
        ];
        final passedCount = checks.where((c) => c['passed'] == true).length;
        final score = ((passedCount / checks.length) * 100).round();

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _profileCompletenessCard(score),
            SizedBox(height: AppSpacing.xl),
            ...checks.map((c) => _verificationNode(
                  c['label'] as String,
                  c['passed'] == true ? 'Verified' : 'Not completed yet',
                  c['passed'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                  AppColors.info,
                  c['passed'] as bool,
                )),
            SizedBox(height: AppSpacing.md),
            if (!hasResume)
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const CandidateProfileHub()),
                ),
                child: const Text("UPLOAD RESUME TO COMPLETE PROFILE"),
              ),
          ],
        );
      },
    );
  }

  Widget _profileCompletenessCard(int score) {
    final scoreColor = score == 100
        ? AppColors.success
        : (score >= 50 ? AppColors.warning : AppColors.error);
    return Container(
      height: 200,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.primaryCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PROFILE COMPLETENESS",
                  style: AppTypography.sectionHeader.copyWith(color: Colors.white70)),
              Icon(Icons.verified_user, color: scoreColor, size: 24),
            ],
          ),
          const Spacer(),
          Text(
            "$score% COMPLETE",
            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 26),
          ),
          Text(
            AppData.name.isEmpty ? "Candidate" : AppData.name,
            style: AppTypography.bodyMediumBold.copyWith(color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  Widget _verificationNode(String t, String s, IconData i, Color c, bool done) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.card(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.withValues(alpha: 0.1),
              child: Icon(i, color: c, size: 18),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: AppTypography.bodyMediumBold),
                  Text(s, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(
              done ? Icons.verified : Icons.pending_outlined,
              color: done ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ],
        ),
      );
}
