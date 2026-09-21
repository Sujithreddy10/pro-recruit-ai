import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_header_stats.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_swipe_card.dart';

class HiringSwipeTab extends StatefulWidget {
  const HiringSwipeTab({super.key});

  @override
  State<HiringSwipeTab> createState() => _HiringSwipeTabState();
}

class _HiringSwipeTabState extends State<HiringSwipeTab> with AutomaticKeepAliveClientMixin {
  int _currentCandidateIdx = 0;
  late Future<List<Map<String, dynamic>>> _applicantsFuture;

  final List<Color> _candidateColors = [
    AppColors.warning,
    AppColors.info,
    Colors.teal,
    Colors.purple,
    AppColors.success,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applicantsFuture = _fetchApplicants();
  }

  Future<List<Map<String, dynamic>>> _fetchApplicants() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('*, profiles(full_name, resume_path)')
        .eq('status', 'applied')
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const RecruiterHeaderStats(),
                SizedBox(height: AppSpacing.md),
                Expanded(
                  child: RecruiterSwipeDecisionCard(
                    name: name,
                    role: role,
                    companyName: companyName,
                    status: status.toString(),
                    createdAt: app['created_at']?.toString() ?? 'Unknown date',
                    accentColor: color,
                    onViewResume: () => _viewResume(app['profiles']?['resume_path']),
                    onReject: () => _handleDecision(false, app['id']),
                    onHire: () => _handleDecision(true, app['id']),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "Queue: ${safeIdx + 1} / ${applicants.length}",
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
