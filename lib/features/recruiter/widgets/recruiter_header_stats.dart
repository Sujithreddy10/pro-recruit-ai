import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterHeaderStats extends StatefulWidget {
  const RecruiterHeaderStats({super.key});

  @override
  State<RecruiterHeaderStats> createState() => _RecruiterHeaderStatsState();
}

class _RecruiterHeaderStatsState extends State<RecruiterHeaderStats> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    final client = Supabase.instance.client;
    final candidates = await client.from('profiles').select().eq('user_role', 'candidate').count(CountOption.exact);
    final jobs = await client.from('jobs').select().count(CountOption.exact);
    final applications = await client.from('applications').select().count(CountOption.exact);

    return {
      'candidates': candidates.count,
      'jobs': jobs.count,
      'applications': applications.count,
    };
  }

  Widget _statColumn(String value, String label) => Column(
        children: [
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: Colors.white38),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'candidates': 0, 'jobs': 0, 'applications': 0};
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.secondary, Color(0xFF1E293B)]),
            borderRadius: AppBorderRadius.large,
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statColumn("${stats['candidates']}", "Pool"),
                    _statColumn("${stats['jobs']}", "Jobs"),
                    _statColumn("${stats['applications']}", "Applications"),
                  ],
                ),
        );
      },
    );
  }
}
