import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class TrustScoreScreen extends StatefulWidget {
  const TrustScoreScreen({super.key});

  @override
  State<TrustScoreScreen> createState() => _TrustScoreScreenState();
}

class _TrustScoreScreenState extends State<TrustScoreScreen> {
  late Future<List<Map<String, dynamic>>> _candidatesFuture;

  @override
  void initState() {
    super.initState();
    _candidatesFuture = _fetchCandidateTrustData();
  }

  Future<List<Map<String, dynamic>>> _fetchCandidateTrustData() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, resume_path, user_role')
        .eq('user_role', 'candidate');
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> _buildChecks(Map<String, dynamic> profile) {
    final hasName = (profile['full_name'] ?? '').toString().isNotEmpty;
    final hasResume = (profile['resume_path'] ?? '').toString().isNotEmpty;
    return [
      {'label': 'Profile Name Set', 'passed': hasName},
      {'label': 'Resume Uploaded', 'passed': hasResume},
    ];
  }

  int _trustScore(List<Map<String, dynamic>> checks) {
    final passed = checks.where((c) => c['passed'] == true).length;
    return ((passed / checks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("Trust Score", style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.error),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _candidatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final candidates = snapshot.data ?? [];
          if (candidates.isEmpty) {
            return Center(child: Text("No candidates found yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)));
          }
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Text("PROFILE COMPLETENESS CHECK", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.xs),
              Text("Real verification of candidate profile data — no fabricated claims.", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              SizedBox(height: AppSpacing.lg),
              ...candidates.map((profile) {
                final checks = _buildChecks(profile);
                final score = _trustScore(checks);
                final name = profile['full_name'] ?? 'Unknown Candidate';
                final scoreColor = score == 100 ? AppColors.success : (score >= 50 ? AppColors.warning : AppColors.error);

                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorderRadius.medium,
                    border: Border.all(color: scoreColor.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: scoreColor.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: scoreColor.withValues(alpha: 0.1),
                            child: Text(name.isNotEmpty ? name[0] : '?', style: AppTypography.bodyMediumBold.copyWith(color: scoreColor)),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(name, style: AppTypography.bodyMediumBold)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(color: scoreColor, borderRadius: AppBorderRadius.small),
                            child: Text("$score%", style: AppTypography.captionBold.copyWith(color: AppColors.textLight)),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      ...checks.map((c) => Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Row(
                              children: [
                                Icon(
                                  c['passed'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: c['passed'] == true ? AppColors.success : AppColors.textMuted,
                                  size: 16,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(c['label'], style: AppTypography.bodySmall),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
