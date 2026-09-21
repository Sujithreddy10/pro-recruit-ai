import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_recruiter_card.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_leaderboard_tile.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> with AutomaticKeepAliveClientMixin {
  bool _isShowingLeaderboard = false;
  late Future<List<List<Map<String, dynamic>>>> _networkFuture;

  final List<Color> _accentColors = [
    AppColors.accentAmber,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    Colors.purple,
    Colors.pinkAccent,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _networkFuture = Future.wait([
      _fetchTopRecruiters(),
      _fetchLeaderboard(),
    ]);
  }

  Future<List<Map<String, dynamic>>> _fetchTopRecruiters() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('role', 'recruiter')
        .limit(10);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    final applications = await Supabase.instance.client
        .from('applications')
        .select('user_id, profiles(full_name)')
        .eq('status', 'shortlisted');

    final rows = List<Map<String, dynamic>>.from(applications);
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final row in rows) {
      final uid = row['user_id'] as String;
      counts[uid] = (counts[uid] ?? 0) + 1;
      names[uid] = row['profiles']?['full_name'] ?? 'Candidate';
    }

    final list = counts.entries
        .map((e) => {'user_id': e.key, 'name': names[e.key] ?? 'Candidate', 'count': e.value})
        .toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: _networkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final recruiters = snapshot.data?[0] ?? [];
        final leaderboard = snapshot.data?[1] ?? [];

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Icon(Icons.hub_outlined, color: AppColors.primary, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    "Talent Ecosystem",
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isShowingLeaderboard = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: !_isShowingLeaderboard
                                ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
                                : null,
                            color: !_isShowingLeaderboard ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: !_isShowingLeaderboard
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "MNC RECRUITERS",
                              style: AppTypography.captionBold.copyWith(
                                color: !_isShowingLeaderboard ? AppColors.textLight : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isShowingLeaderboard = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: _isShowingLeaderboard
                                ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
                                : null,
                            color: _isShowingLeaderboard ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: _isShowingLeaderboard
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "GLOBAL LEADERBOARD",
                              style: AppTypography.captionBold.copyWith(
                                color: _isShowingLeaderboard ? AppColors.textLight : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              if (!_isShowingLeaderboard) ...[
                if (recruiters.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        "No recruiters found yet.",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...recruiters.asMap().entries.map((e) {
                    final name = e.value['full_name'] ?? 'Recruiter';
                    final color = _accentColors[e.key % _accentColors.length];
                    return CandidateRecruiterCard(
                      name: name,
                      role: "Recruiter",
                      accentColor: color,
                      onReferralRequested: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Elite Referral Request Sent to $name successful"),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  }),
              ] else ...[
                if (leaderboard.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        "No shortlisted candidates yet.",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...leaderboard.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final row = entry.value;
                    final colors = [
                      AppColors.accentAmber,
                      Colors.blueGrey,
                      Colors.brown,
                      AppColors.info,
                      Colors.teal,
                    ];
                    return CandidateLeaderboardTile(
                      rank: rank,
                      name: row['name'] ?? 'Candidate',
                      title: "Shortlisted Candidate",
                      score: row['count'] ?? 0,
                      accentColor: colors[entry.key % colors.length],
                    );
                  }),
              ],
            ],
          ),
        );
      },
    );
  }
}
