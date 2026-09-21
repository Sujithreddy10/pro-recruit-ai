import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_header_stats.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/fraud_defense_scanner.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/autonomous_intake_module.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/salary_hub_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/talent_match_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/ai_assistant_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/candidate_crm_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/trust_score_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/scheduler_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/collab_hub_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/kpi_analytics_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/job_post_optimizer_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/outreach_composer_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/job_board_screen.dart';

class RecruiterConsoleTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const RecruiterConsoleTab({super.key, this.onNavigateToTab});

  @override
  State<RecruiterConsoleTab> createState() => _RecruiterConsoleTabState();
}

class _RecruiterConsoleTabState extends State<RecruiterConsoleTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, int>> _pipelineCountsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pipelineCountsFuture = _fetchPipelineCounts();
  }

  Future<Map<String, int>> _fetchPipelineCounts() async {
    final data = await Supabase.instance.client.from('applications').select('status');
    final rows = List<Map<String, dynamic>>.from(data);

    final counts = <String, int>{'applied': 0, 'shortlisted': 0, 'rejected': 0};
    for (final row in rows) {
      final status = row['status'] as String? ?? 'applied';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  void _openFraudScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FraudDefenseScanner(),
    );
  }

  void _openIntakeChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AutonomousIntakeModule(),
    );
  }

  Widget _snapshotStat(String value, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: AppTypography.headlineLarge.copyWith(color: color, fontSize: 20)),
            SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _pipelineSnapshotCard() {
    return FutureBuilder<Map<String, int>>(
      future: _pipelineCountsFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'applied': 0, 'shortlisted': 0, 'rejected': 0};
        return Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.elevatedCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text("PIPELINE SNAPSHOT", style: AppTypography.sectionHeader),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _snapshotStat("${counts['applied']}", "Applied", AppColors.info,
                            () => widget.onNavigateToTab?.call(2)),
                        _snapshotStat("${counts['shortlisted']}", "Shortlisted", AppColors.success,
                            () => widget.onNavigateToTab?.call(2)),
                        _snapshotStat("${counts['rejected']}", "Rejected", AppColors.error,
                            () => widget.onNavigateToTab?.call(2)),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _navTile(String t, IconData i, Color c, String s, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorderRadius.medium,
            border: Border.all(color: c.withValues(alpha: 0.15)),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.06)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(i, color: c, size: 26),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: AppTypography.bodyMediumBold),
                  Text(s, style: AppTypography.captionBold.copyWith(color: c)),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1100 ? 6 : screenWidth > 700 ? 4 : 2;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
      children: [
        const RecruiterHeaderStats(),
        SizedBox(height: AppSpacing.xl),
        _pipelineSnapshotCard(),
        SizedBox(height: AppSpacing.xl),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1,
          children: [
            _navTile("Talent Match", Icons.psychology_outlined, Colors.deepPurple, "AI Rank Score",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TalentMatchScreen()))),
            _navTile("Intake Agent", Icons.support_agent, Colors.teal, "Start Chat", onTap: _openIntakeChat),
            _navTile("AI Assistant", Icons.auto_fix_high, Colors.deepPurple, "Draft Messages & JDs",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIAssistantScreen()))),
            _navTile("Fraud Defense", Icons.gpp_maybe_outlined, AppColors.error, "Deep-Fake Detector",
                onTap: _openFraudScanner),
            _navTile("Trust Score", Icons.verified_user, AppColors.error, "Profile Verification",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TrustScoreScreen()))),
            _navTile("Salary Hub", Icons.analytics, Colors.indigo, "Market Intel",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SalaryHubScreen()))),
            _navTile("Candidate CRM", Icons.recent_actors, Colors.deepOrange, "Talent History",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CandidateCRMScreen()))),
            _navTile("Scheduler", Icons.event_available, Colors.lightBlue, "Interview Slots",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SchedulerScreen()))),
            _navTile("Collab Hub", Icons.forum, Colors.deepPurple, "Candidate Notes",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CollabHubScreen()))),
            _navTile("KPI Analytics", Icons.speed, Colors.pinkAccent, "Success Meta",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const KPIAnalyticsScreen()))),
            _navTile("Job Post Optimizer", Icons.rocket_launch, Colors.deepOrangeAccent, "AI Clarity & Bias Check",
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const JobPostOptimizerScreen()))),
            _navTile("Outreach Composer", Icons.cloud, Colors.lightBlue, "Personalized AI Messages",
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const OutreachComposerScreen()))),
            _navTile("Post a Job", Icons.add_business_outlined, Colors.deepOrange, "Manage Listings",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const JobBoardScreen()))),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
