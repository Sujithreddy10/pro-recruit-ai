import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_header_stats.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_console_widgets.dart';
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
    final data =
        await Supabase.instance.client.from('applications').select('status');
    final rows = List<Map<String, dynamic>>.from(data);

    final counts = <String, int>{'applied': 0, 'shortlisted': 0, 'rejected': 0};
    for (final row in rows) {
      final status = row['status'] as String? ?? 'applied';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  void _openFraudScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => const FraudDefenseScanner(),
      ),
    );
  }

  void _openIntakeChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => const AutonomousIntakeModule(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1100 ? 6 : screenWidth > 700 ? 4 : 2;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          const RecruiterHeaderStats(),
          SizedBox(height: AppSpacing.xl),
          RecruiterConsoleSnapshotCard(
            pipelineCountsFuture: _pipelineCountsFuture,
            onNavigateToTab: widget.onNavigateToTab,
          ),
          SizedBox(height: AppSpacing.xl),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
            children: [
              RecruiterConsoleNavTile(
                title: "Talent Match",
                icon: Icons.psychology_outlined,
                color: Colors.deepPurple,
                subtitle: "AI Rank Score",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const TalentMatchScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Intake Agent",
                icon: Icons.support_agent,
                color: Colors.teal,
                subtitle: "Start Chat",
                onTap: _openIntakeChat,
              ),
              RecruiterConsoleNavTile(
                title: "AI Assistant",
                icon: Icons.auto_fix_high,
                color: Colors.deepPurple,
                subtitle: "Draft Messages & JDs",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AIAssistantScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Fraud Defense",
                icon: Icons.gpp_maybe_outlined,
                color: AppColors.error,
                subtitle: "Deep-Fake Detector",
                onTap: _openFraudScanner,
              ),
              RecruiterConsoleNavTile(
                title: "Trust Score",
                icon: Icons.verified_user,
                color: AppColors.error,
                subtitle: "Profile Verification",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const TrustScoreScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Salary Hub",
                icon: Icons.analytics,
                color: Colors.indigo,
                subtitle: "Market Intel",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SalaryHubScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Candidate CRM",
                icon: Icons.recent_actors,
                color: Colors.deepOrange,
                subtitle: "Talent History",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const CandidateCRMScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Scheduler",
                icon: Icons.event_available,
                color: Colors.lightBlue,
                subtitle: "Interview Slots",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SchedulerScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Collab Hub",
                icon: Icons.forum,
                color: Colors.deepPurple,
                subtitle: "Candidate Notes",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const CollabHubScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "KPI Analytics",
                icon: Icons.speed,
                color: Colors.pinkAccent,
                subtitle: "Success Meta",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const KPIAnalyticsScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Job Post Optimizer",
                icon: Icons.rocket_launch,
                color: Colors.deepOrangeAccent,
                subtitle: "AI Clarity & Bias Check",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const JobPostOptimizerScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Outreach Composer",
                icon: Icons.cloud,
                color: Colors.lightBlue,
                subtitle: "Personalized AI Messages",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const OutreachComposerScreen()),
                ),
              ),
              RecruiterConsoleNavTile(
                title: "Post a Job",
                icon: Icons.add_business_outlined,
                color: Colors.deepOrange,
                subtitle: "Manage Listings",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const JobBoardScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
