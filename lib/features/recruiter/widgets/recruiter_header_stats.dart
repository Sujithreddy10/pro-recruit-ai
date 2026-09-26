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

  Widget _statColumn(String value, String label, bool isDark) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'candidates': 0, 'jobs': 0, 'applications': 0};
        return Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: AppBorderRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 44,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn("${stats['candidates']}", "POOL", isDark),
                    Container(
                      height: 26,
                      width: 1,
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                    ),
                    _statColumn("${stats['jobs']}", "JOBS", isDark),
                    Container(
                      height: 26,
                      width: 1,
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                    ),
                    _statColumn("${stats['applications']}", "APPLICATIONS", isDark),
                  ],
                ),
        );
      },
    );
  }
}
