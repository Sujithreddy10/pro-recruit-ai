import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_org_cards.dart';
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

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              RecruiterOrgHeader(
                totalUsers: stats['candidates']! + stats['recruiters']!,
              ),
              SizedBox(height: AppSpacing.xl),
              Text("PLATFORM STATS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              RecruiterOrgStatCard(
                label: "Recruiters",
                count: stats['recruiters']!,
                icon: Icons.groups,
                accentColor: AppColors.info,
              ),
              RecruiterOrgStatCard(
                label: "Candidates",
                count: stats['candidates']!,
                icon: Icons.person_outline,
                accentColor: Colors.teal,
              ),
              RecruiterOrgStatCard(
                label: "Active Jobs",
                count: stats['jobs']!,
                icon: Icons.business_center_outlined,
                accentColor: Colors.indigo,
              ),
              RecruiterOrgStatCard(
                label: "Total Applications",
                count: stats['applications']!,
                icon: Icons.description_outlined,
                accentColor: AppColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }
}
