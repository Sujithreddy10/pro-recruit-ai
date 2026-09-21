import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_trust_card.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';

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

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              CandidateTrustCard(
                score: score,
                userName: AppData.name.isEmpty ? "Candidate" : AppData.name,
              ),
              SizedBox(height: AppSpacing.xl),
              ...checks.map((c) => CandidateVerificationTile(
                    title: c['label'] as String,
                    subtitle: c['passed'] == true ? 'Verified' : 'Not completed yet',
                    icon: c['passed'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                    accentColor: AppColors.info,
                    isCompleted: c['passed'] as bool,
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
          ),
        );
      },
    );
  }
}
