import 'package:pro_recruit_ai/features/recruiter/screens/talent_match_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/ai_assistant_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/candidate_crm_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/trust_score_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/kpi_analytics_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/job_board_screen.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/scheduler_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/collab_hub_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/subscription_plan_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/usage_credits_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';




// Entry Point for the Recruiter World
class RecruiterRoot extends StatelessWidget {
  const RecruiterRoot({super.key});
  @override
  Widget build(BuildContext context) {
    return const RecruiterMasterHub();
  }
}

class RecruiterMasterHub extends StatefulWidget {
  const RecruiterMasterHub({super.key});
  @override
  State<RecruiterMasterHub> createState() => _RecruiterMasterHubState();
}

class _RecruiterMasterHubState extends State<RecruiterMasterHub> {
  int _idx = 0;
  final GlobalKey<ScaffoldState> _scafKey = GlobalKey<ScaffoldState>();

  int _currentCandidateIdx = 0;
  late Future<List<Map<String, dynamic>>> _applicantsFuture;
  final List<Color> _candidateColors = [
    AppColors.warning,
    AppColors.info,
    Colors.teal,
    Colors.purple,
    AppColors.success,
  ];

  Future<List<Map<String, dynamic>>> _fetchApplicants() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('*, profiles(full_name, resume_path)')
        .eq('status', 'applied')
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
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

  Future<List<Map<String, dynamic>>> _fetchPendingOffers() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, created_at, profiles(full_name)')
        .eq('status', 'offer_sent')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchSecuredOffers() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, created_at, profiles(full_name)')
        .eq('status', 'hired')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _markOfferAccepted(int applicationId) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': 'hired', 'status_updated_at': DateTime.now().toIso8601String()})
          .eq('id', applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Marked as Hired"), backgroundColor: AppColors.success),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<Map<String, int>> _fetchOrgStats() async {
    final client = Supabase.instance.client;

    final recruiters = await client.from('profiles').select('id').eq('user_role', 'recruiter');
    final candidates = await client.from('profiles').select('id').eq('user_role', 'candidate');
    final jobs = await client.from('jobs').select('id');
    final applications = await client.from('applications').select('id');

    return {
      'recruiters': List.from(recruiters).length,
      'candidates': List.from(candidates).length,
      'jobs': List.from(jobs).length,
      'applications': List.from(applications).length,
    };
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded by this candidate.")),
      );
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('resumes')
          .createSignedUrl(resumePath, 60 * 5);

      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open resume URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load resume: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus, 'status_updated_at': DateTime.now().toIso8601String()})
          .eq('id', applicationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _applicantsFuture = _fetchApplicants();
  }

  Future<void> _handleDecision(bool approved, int applicationId) async {
    final newStatus = approved ? 'shortlisted' : 'rejected';
    await _updateApplicationStatus(applicationId, newStatus);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved ? "Candidate Shortlisted" : "Candidate Archived"),
        backgroundColor: approved ? AppColors.success : AppColors.error,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _currentCandidateIdx = 0;
      _applicantsFuture = _fetchApplicants();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scafKey,
      extendBodyBehindAppBar: true,
      drawer: _buildMasterDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_open_rounded, color: AppColors.primary),
          onPressed: () => _scafKey.currentState!.openDrawer(),
        ),
        title: Text("Career Root Console", style: GoogleFonts.lobster(color: AppColors.primary)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBackgroundWrapper(
        child: IndexedStack(index: _idx, children: [
          _recConsoleGrid(),
          _candidateDecisionSwipeTab(),
          _recHiringPipelineDashboard(),
          _recOffersReleaseHub(),
          _recEnterpriseOrgHub(),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Console"),
          BottomNavigationBarItem(icon: Icon(Icons.swipe_rounded), label: "Hiring"),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), label: "Pipeline"),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.business_center), label: "Org"),
        ],
      ),
    );
  }

  Widget _candidateDecisionSwipeTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final applicants = snapshot.data ?? [];
        if (applicants.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Text("No applicants yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            ),
          );
        }

        final safeIdx = _currentCandidateIdx % applicants.length;
        final app = applicants[safeIdx];
        final name = app['profiles']?['full_name'] ?? 'Unknown Candidate';
        final role = app['job_title'] ?? 'N/A';
        final companyName = app['company_name'] ?? 'N/A';
        final status = app['status'] ?? 'applied';
        final color = _candidateColors[safeIdx % _candidateColors.length];

        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          child: Column(children: [
            _recHeaderStats(),
            SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: AppDecorations.elevatedCard,
                child: Column(children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: AppBorderRadius.topLarge,
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: color,
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: AppTypography.titleMedium),
                          Text("$role @ $companyName", style: AppTypography.bodySmallBold.copyWith(color: color)),
                        ]),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("APPLICATION STATUS", style: AppTypography.sectionHeader),
                        SizedBox(height: AppSpacing.sm),
                        Row(children: [
                          Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Text(status.toString().toUpperCase(), style: AppTypography.bodySmallBold.copyWith(color: AppColors.warning)),
                        ]),
                        SizedBox(height: AppSpacing.xl),
                        Text("APPLIED ON", style: AppTypography.sectionHeader),
                        SizedBox(height: AppSpacing.sm),
                        Text(app['created_at']?.toString().split('T').first ?? 'Unknown date', style: AppTypography.bodyMedium),
                        SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => _viewResume(app['profiles']?['resume_path']),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: Text("VIEW RESUME", style: AppTypography.bodySmallBold),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Row(children: [
                      Expanded(child: _decisionBtn(Icons.close, "REJECT", AppColors.error, () => _handleDecision(false, app['id']))),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: _decisionBtn(Icons.check, "HIRE", AppColors.success, () => _handleDecision(true, app['id']))),
                    ]),
                  )
                ]),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text("Queue: ${safeIdx + 1} / ${applicants.length}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        );
      },
    );
  }

  Widget _decisionBtn(IconData i, String l, Color c, VoidCallback o) => ElevatedButton.icon(
        onPressed: o,
        icon: Icon(i, size: 18),
        label: Text(l, style: AppTypography.bodySmallBold.copyWith(color: AppColors.textLight)),
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(0, 55),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        ),
      );

  Widget _recEnterpriseOrgHub() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchOrgStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final stats = snapshot.data ?? {'recruiters': 0, 'candidates': 0, 'jobs': 0, 'applications': 0};

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _orgHeader(stats['candidates']! + stats['recruiters']!),
            SizedBox(height: AppSpacing.xl),
            Text("PLATFORM STATS", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            _orgStatCard("Recruiters", stats['recruiters']!, Icons.groups, AppColors.info),
            _orgStatCard("Candidates", stats['candidates']!, Icons.person_outline, Colors.teal),
            _orgStatCard("Active Jobs", stats['jobs']!, Icons.business_center_outlined, Colors.indigo),
            _orgStatCard("Total Applications", stats['applications']!, Icons.description_outlined, AppColors.warning),
          ],
        );
      },
    );
  }

  Widget _orgHeader(int totalUsers) => Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.primaryCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PLATFORM OVERVIEW", style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent)),
            SizedBox(height: AppSpacing.xs),
            Text("$totalUsers Total Users", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight)),
            Text("Live counts from your Supabase backend", style: AppTypography.caption.copyWith(color: Colors.white60)),
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.bodyMediumBold)),
            Text("$count", style: AppTypography.titleMedium.copyWith(color: color)),
          ],
        ),
      );

  Widget _recOffersReleaseHub() {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait([_fetchPendingOffers(), _fetchSecuredOffers()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final pending = snapshot.data?[0] ?? [];
        final secured = snapshot.data?[1] ?? [];

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _offerHeader(pending.length, secured.length),
            SizedBox(height: AppSpacing.xl),
            Text("PENDING OFFERS", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            if (pending.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text("No pending offers yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              )
            else
              ...pending.map((o) => _offerTrackingCard(
                    o['profiles']?['full_name'] ?? 'Unknown Candidate',
                    o['job_title'] ?? 'N/A',
                    o['id'],
                  )),
            SizedBox(height: AppSpacing.xxl),
            Text("RECENTLY SECURED", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            if (secured.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text("No offers secured yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              )
            else
              ...secured.map((o) => _securedOfferTile(
                    o['profiles']?['full_name'] ?? 'Unknown Candidate',
                    o['job_title'] ?? 'N/A',
                  )),
          ],
        );
      },
    );
  }

  Widget _offerHeader(int pendingCount, int securedCount) {
    final total = pendingCount + securedCount;
    final rate = total == 0 ? 0 : ((securedCount / total) * 100).round();
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF059669)]),
        borderRadius: AppBorderRadius.large,
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("OFFER ACCEPTANCE: $rate%", style: AppTypography.sectionHeader.copyWith(color: Colors.greenAccent), overflow: TextOverflow.ellipsis),
              SizedBox(height: AppSpacing.xs),
              Text("$securedCount Offers Secured", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18), overflow: TextOverflow.ellipsis),
              Text("$pendingCount pending", style: AppTypography.caption.copyWith(color: Colors.white60)),
            ]),
          ),
          SizedBox(width: AppSpacing.md),
          Icon(Icons.verified_user, color: AppColors.textLight, size: 40),
        ],
      ),
    );
  }

  Widget _offerTrackingCard(String name, String role, int applicationId) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.warning.withValues(alpha: 0.06), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 18),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(name, style: AppTypography.bodyMediumBold, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: AppDecorations.pill(AppColors.warning),
              child: Text("PENDING", style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
            ),
          ]),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.only(left: 44),
            child: Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF064E3B), AppColors.success]),
                borderRadius: AppBorderRadius.small,
                boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: () => _markOfferAccepted(applicationId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textLight,
                ),
                child: Text("MARK ACCEPTED", style: AppTypography.captionBold.copyWith(color: AppColors.textLight)),
              ),
            ),
          ),
        ]),
      );

  Widget _securedOfferTile(String name, String role) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.success.withValues(alpha: 0.08), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTypography.bodyMediumBold),
              Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ]),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(AppColors.success),
            child: Text("HIRED", style: AppTypography.captionBold.copyWith(color: AppColors.success)),
          ),
        ]),
      );

  Widget _recHiringPipelineDashboard() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchPipelineCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final counts = snapshot.data ?? {'applied': 0, 'shortlisted': 0, 'rejected': 0};
        final total = counts.values.fold(0, (a, b) => a + b);
        double ratio(int v) => total == 0 ? 0 : v / total;

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _pipelineHeader(total),
            SizedBox(height: AppSpacing.xl),
            _pipelineStageCard("Applied (Awaiting Review)", "${counts['applied']} Candidates", AppColors.info, ratio(counts['applied']!)),
            _pipelineStageCard("Shortlisted", "${counts['shortlisted']} Candidates", AppColors.success, ratio(counts['shortlisted']!)),
            _pipelineStageCard("Rejected", "${counts['rejected']} Candidates", AppColors.error, ratio(counts['rejected']!)),
          ],
        );
      },
    );
  }

  Widget _pipelineHeader(int total) => Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.primaryCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LIVE PIPELINE", style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent)),
            SizedBox(height: AppSpacing.xs),
            Text("Total Applications: $total", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
            Text("Real-time candidate status across all roles", style: AppTypography.caption.copyWith(color: Colors.white60)),
          ],
        ),
      );

  Widget _pipelineStageCard(String title, String count, Color color, double progress) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: AppTypography.bodyMediumBold),
              Text(count, style: AppTypography.bodySmallBold.copyWith(color: color)),
            ]),
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppBorderRadius.small,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _pipelineSnapshotCard() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchPipelineCounts(),
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
                        _snapshotStat("${counts['applied']}", "Applied", AppColors.info, () => setState(() => _idx = 2)),
                        _snapshotStat("${counts['shortlisted']}", "Shortlisted", AppColors.success, () => setState(() => _idx = 2)),
                        _snapshotStat("${counts['rejected']}", "Rejected", AppColors.error, () => setState(() => _idx = 2)),
                      ],
                    ),
            ],
          ),
        );
      },
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

  Widget _recConsoleGrid() => ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
        children: [
          _recHeaderStats(),
          SizedBox(height: AppSpacing.xl),
          _pipelineSnapshotCard(),
          SizedBox(height: AppSpacing.xl),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
            children: [
              _navTile("Talent Match", Icons.psychology_outlined, Colors.deepPurple, "AI Rank Score",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TalentMatchScreen()))),
              _navTile("Intake Agent", Icons.support_agent, Colors.teal, "Start Chat", onTap: _openIntakeChat),
              _navTile("AI Assistant", Icons.auto_fix_high, Colors.deepPurple, "Draft Messages & JDs",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIAssistantScreen()))),
              _navTile("Fraud Defense", Icons.gpp_maybe_outlined, AppColors.error, "Deep-Fake Detector", onTap: _openFraudScanner),
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
              _comingSoonTile("Onboarding Pro", Icons.rocket_launch, Colors.deepOrangeAccent, "Day 0 Engine"),
              _comingSoonTile("Resume Vault", Icons.cloud, Colors.lightBlue, "Storage Stats"),
              _navTile("Post a Job", Icons.add_business_outlined, Colors.deepOrange, "Manage Listings",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const JobBoardScreen()))),
            ],
          ),
          const SizedBox(height: 100),
        ],
      );

  Widget _comingSoonTile(String t, IconData i, Color c, String s) => GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$t is coming soon"), behavior: SnackBarBehavior.floating),
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppBorderRadius.medium,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(i, color: c.withValues(alpha: 0.5), size: 32),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: AppBorderRadius.small),
                child: Text("SOON", style: AppTypography.captionBold.copyWith(color: AppColors.textMuted)),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: AppTypography.bodySmallBold.copyWith(color: AppColors.textMuted)),
              Text(s, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ]),
          ]),
        ),
      );

  // --- DRAWER (fixed: every item now navigates somewhere real) ---
  Widget _buildMasterDrawer() => Drawer(
        backgroundColor: Colors.white,
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E40AF)]),
            ),
            accountName: const Text("Recruiter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            accountEmail: const Text("Enterprise Global Access ✓", style: TextStyle(color: Colors.white70, fontSize: 10)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: CustomPaint(
                size: const Size(40, 40),
                painter: AshWheelPainter(wheelColor: const Color(0xFF1E40AF)),
              ),
            ),
          ),
          _drawerItem("Team Management", Icons.groups, const Color(0xFF2563EB), onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => const FeatureDisplayPage(
                  title: "Team Management",
                  color: Color(0xFF2563EB),
                  icon: Icons.groups,
                ),
              ),
            );
          }),
          _drawerItem("Analytics", Icons.query_stats, Colors.purple, onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => const KPIAnalyticsScreen()));
          }),
          _drawerItem("Subscription Plan", Icons.workspace_premium_rounded, const Color(0xFFEA580C), onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const SubscriptionPlanScreen()),
            );
          }),
          _drawerItem("Usage Credits", Icons.account_balance_wallet_rounded, const Color(0xFF16A34A), onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const UsageCreditsScreen()),
            );
          }),
          const Divider(),
          AnimatedBuilder(
            animation: ThemeController.instance,
            builder: (context, _) => SwitchListTile(
              secondary: Icon(
                ThemeController.instance.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF1E40AF),
              ),
              title: const Text("Dark Mode", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
              value: ThemeController.instance.isDarkMode,
              onChanged: (v) => ThemeController.instance.setDarkMode(v),
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            title: const Text("Logout", style: TextStyle(color: Colors.black87, fontSize: 13)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          SizedBox(height: AppSpacing.lg),
        ]),
      );

  Widget _drawerItem(String t, IconData i, Color c, {VoidCallback? onTap}) => ListTile(
        leading: Icon(i, color: c),
        title: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
        onTap: onTap,
      );

  Widget _recHeaderStats() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchOrgStats(),
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
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _s("${stats['candidates']}", "Pool"),
                  _s("${stats['jobs']}", "Jobs"),
                  _s("${stats['applications']}", "Applications"),
                ]),
        );
      },
    );
  }

  Widget _s(String v, String l) => Column(children: [
        Text(v, style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20)),
        Text(l, style: AppTypography.caption.copyWith(color: Colors.white38)),
      ]);

  Widget _navTile(String t, IconData i, Color c, String s, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (cv) => FeatureDisplayPage(title: t, color: c, icon: i))),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorderRadius.medium,
            border: Border.all(color: c.withValues(alpha: 0.15)),
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.06)]),
                shape: BoxShape.circle,
              ),
              child: Icon(i, color: c, size: 26),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: AppTypography.bodyMediumBold),
              Text(s, style: AppTypography.captionBold.copyWith(color: c)),
            ]),
          ]),
        ),
      );
}

class FraudDefenseScanner extends StatefulWidget {
  const FraudDefenseScanner({super.key});
  @override
  State<FraudDefenseScanner> createState() => _FraudDefenseScannerState();
}

class _FraudDefenseScannerState extends State<FraudDefenseScanner> {
  late Future<List<Map<String, dynamic>>> _flagsFuture;

  @override
  void initState() {
    super.initState();
    _flagsFuture = _runIntegrityCheck();
  }

  Future<List<Map<String, dynamic>>> _runIntegrityCheck() async {
    final client = Supabase.instance.client;

    final apps = await client
        .from('applications')
        .select('id, user_id, job_title, company_name, profiles(full_name, resume_path)');
    final rows = List<Map<String, dynamic>>.from(apps);

    final seen = <String, int>{};
    for (final row in rows) {
      final key = '${row['user_id']}_${row['job_title']}_${row['company_name']}';
      seen[key] = (seen[key] ?? 0) + 1;
    }

    final flagged = <Map<String, dynamic>>[];
    for (final row in rows) {
      final name = row['profiles']?['full_name'] ?? 'Unknown Candidate';
      final resumePath = row['profiles']?['resume_path'];
      final key = '${row['user_id']}_${row['job_title']}_${row['company_name']}';
      final duplicateCount = seen[key] ?? 1;
      final missingResume = (resumePath == null || resumePath.toString().isEmpty);

      if (duplicateCount > 1 || missingResume) {
        flagged.add({
          'name': name,
          'job_title': row['job_title'],
          'company_name': row['company_name'],
          'duplicate_count': duplicateCount,
          'missing_resume': missingResume,
        });
      }
    }

    return flagged;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.topLarge,
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _flagsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final flags = snapshot.data ?? [];

          return Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("APPLICATION INTEGRITY CHECK", style: AppTypography.sectionHeader),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                SizedBox(height: AppSpacing.xs),
                Text("Flags duplicate applications and missing resumes — no fabricated claims.", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: flags.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gpp_good, color: AppColors.success, size: 60),
                              SizedBox(height: AppSpacing.md),
                              Text("No integrity issues found", style: AppTypography.bodyMediumBold),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: flags.length,
                          itemBuilder: (context, i) {
                            final f = flags[i];
                            return Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.05),
                                borderRadius: AppBorderRadius.medium,
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f['name'], style: AppTypography.bodyMediumBold),
                                  Text("${f['job_title']} @ ${f['company_name']}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                  SizedBox(height: AppSpacing.sm),
                                  if (f['duplicate_count'] > 1)
                                    Row(children: [
                                      Icon(Icons.content_copy, size: 14, color: AppColors.warning),
                                      SizedBox(width: AppSpacing.xs),
                                      Text("Applied ${f['duplicate_count']}x to this same role", style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                                    ]),
                                  if (f['missing_resume'])
                                    Padding(
                                      padding: EdgeInsets.only(top: AppSpacing.xs),
                                      child: Row(children: [
                                        Icon(Icons.description_outlined, size: 14, color: AppColors.error),
                                        SizedBox(width: AppSpacing.xs),
                                        Text("No resume uploaded", style: AppTypography.captionBold.copyWith(color: AppColors.error)),
                                      ]),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final bool isUser;
  ChatMessage({required this.sender, required this.text, required this.isUser});
}

class AutonomousIntakeModule extends StatefulWidget {
  const AutonomousIntakeModule({super.key});
  @override
  State<AutonomousIntakeModule> createState() => _AutonomousIntakeModuleState();
}

class _AutonomousIntakeModuleState extends State<AutonomousIntakeModule> {
  final TextEditingController _msgCtrl = TextEditingController();

  final List<ChatMessage> _messages = [
    ChatMessage(sender: "Agent", text: "Elite Intake Agent Online. Tell me about the role and availability.", isUser: false),
  ];
  bool _isProcessing = false;

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.isEmpty || _isProcessing) return;
    final String userText = _msgCtrl.text;
    _msgCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(sender: "User", text: userText, isUser: true));
      _isProcessing = true;
    });
    try {
      // Calls the Supabase Edge Function 'intake-chat', which holds the
      // Gemini API key server-side. The key never ships inside the app.
      final response = await Supabase.instance.client.functions.invoke(
        'intake-chat',
        body: {'message': userText},
      );

      if (response.status != 200) {
        throw 'Server error (${response.status})';
      }

      final data = response.data as Map<String, dynamic>;
      final text = data['text'] as String? ?? "...";
      setState(() => _messages.add(ChatMessage(sender: "Agent", text: text, isUser: false)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage(sender: "Agent", text: "Error: $e", isUser: false)));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.topLarge,
      ),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI INTAKE AGENT", style: AppTypography.sectionHeader),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _bubble(_messages[i]),
          ),
        ),
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Describe the role...",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Colors.teal]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: IconButton(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isProcessing ? null : _sendMessage,
              ),
            )
          ]),
        )
      ]),
    );
  }

  Widget _bubble(ChatMessage msg) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.sender, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: AppBorderRadius.medium,
              ),
              child: Text(
                msg.text,
                style: AppTypography.bodySmall.copyWith(
                  color: msg.isUser ? AppColors.textLight : AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class FeatureDisplayPage extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  const FeatureDisplayPage({super.key, required this.title, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.textLight)),
        backgroundColor: color,
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            SizedBox(height: AppSpacing.lg),
            Text("$title Module Active", style: AppTypography.headlineLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class CandidateMasterHub extends StatelessWidget {
  const CandidateMasterHub({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Candidate Hub", style: AppTypography.bodyMedium)));
  }
}



class SalaryHubScreen extends StatefulWidget {
  const SalaryHubScreen({super.key});
  @override
  State<SalaryHubScreen> createState() => _SalaryHubScreenState();
}

class _SalaryHubScreenState extends State<SalaryHubScreen> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobsWithSalary();
  }

  Future<List<Map<String, dynamic>>> _fetchJobsWithSalary() async {
    final data = await Supabase.instance.client
        .from('jobs')
        .select('id, title, company, salary_range')
        .order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("Salary Hub", style: AppTypography.titleMedium.copyWith(color: Colors.indigo)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.indigo),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(child: Text("No job listings found yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)));
          }
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.secondary, Color(0xFF312E81)]),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("LIVE MARKET BENCHMARKS", style: AppTypography.sectionHeader.copyWith(color: Colors.indigoAccent)),
                    SizedBox(height: AppSpacing.xs),
                    Text("${jobs.length} Active Job Postings", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
                    Text("Real salary data across your open roles", style: AppTypography.caption.copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              ...jobs.map((j) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                          child: const Icon(Icons.business_center_outlined, color: Colors.indigo, size: 20),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(j['title'] ?? 'N/A', style: AppTypography.bodyMediumBold),
                              Text(j['company'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                          child: Text(j['salary_range'] ?? 'N/A', style: AppTypography.bodySmallBold.copyWith(color: AppColors.success)),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
