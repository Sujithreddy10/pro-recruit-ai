import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class EnterpriseOrgTab extends StatefulWidget {
  const EnterpriseOrgTab({super.key});

  @override
  State<EnterpriseOrgTab> createState() => _EnterpriseOrgTabState();
}

class _EnterpriseOrgTabState extends State<EnterpriseOrgTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, int>> _orgStatsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _orgStatsFuture = _loadOrgStats();
  }

  Future<Map<String, int>> _loadOrgStats() async {
    final client = Supabase.instance.client;

    final recruiters = await client
        .from('profiles')
        .select()
        .eq('user_role', 'recruiter')
        .count(CountOption.exact);
    final candidates = await client
        .from('profiles')
        .select()
        .eq('user_role', 'candidate')
        .count(CountOption.exact);
    final jobs = await client.from('jobs').select().count(CountOption.exact);
    final applications =
        await client.from('applications').select().count(CountOption.exact);

    return {
      'recruiters': recruiters.count,
      'candidates': candidates.count,
      'jobs': jobs.count,
      'applications': applications.count,
    };
  }

  Widget _orgHeader(int totalUsers) => Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.primaryCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PLATFORM OVERVIEW",
              style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              "$totalUsers Total Users",
              style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
            ),
            Text(
              "Live counts from your Supabase backend",
              style: AppTypography.caption.copyWith(color: Colors.white60),
            ),
          ],
        ),
      );

  Widget _orgStatCard(String label, int count, IconData icon, Color color) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.bodyMediumBold)),
            Text("$count", style: AppTypography.titleMedium.copyWith(color: color)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, int>>(
      future: _orgStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
          );
        }
        final stats = snapshot.data ??
            {'recruiters': 0, 'candidates': 0, 'jobs': 0, 'applications': 0};

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _orgHeader(stats['candidates']! + stats['recruiters']!),
            SizedBox(height: AppSpacing.xl),
            Text("PLATFORM STATS", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            _orgStatCard(
              "Recruiters",
              stats['recruiters']!,
              Icons.groups,
              AppColors.info,
            ),
            _orgStatCard(
              "Candidates",
              stats['candidates']!,
              Icons.person_outline,
              Colors.teal,
            ),
            _orgStatCard(
              "Active Jobs",
              stats['jobs']!,
              Icons.business_center_outlined,
              Colors.indigo,
            ),
            _orgStatCard(
              "Total Applications",
              stats['applications']!,
              Icons.description_outlined,
              AppColors.warning,
            ),
          ],
        );
      },
    );
  }
}
