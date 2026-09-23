import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import '../widgets/recruiter_swipe_card.dart';
import '../widgets/recruiter_header_stats.dart';

class HiringSwipeTab extends StatefulWidget {
  const HiringSwipeTab({super.key});

  @override
  State<HiringSwipeTab> createState() => _HiringSwipeTabState();
}

class _HiringSwipeTabState extends State<HiringSwipeTab> with AutomaticKeepAliveClientMixin {
  int _currentCandidateIdx = 0;
  String _selectedRole = "All Roles";
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

  Widget _buildRolePills(List<Map<String, dynamic>> allApplicants) {
    final Map<String, int> counts = {"All Roles": allApplicants.length};
    for (final app in allApplicants) {
      final role = (app['job_title'] ?? 'General').toString().trim();
      if (role.isNotEmpty) {
        counts[role] = (counts[role] ?? 0) + 1;
      }
    }

    final roles = counts.keys.toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = _selectedRole == role;
          final count = counts[role] ?? 0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_selectedRole != role) {
                  setState(() {
                    _selectedRole = role;
                    _currentCandidateIdx = 0;
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 8.0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }

        final allApplicants = snapshot.data ?? [];
        if (allApplicants.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                  SizedBox(height: AppSpacing.md),
                  Text("No pending applicants.", style: AppTypography.bodyMediumBold),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "All applied candidates have been reviewed.",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredApplicants = _selectedRole == "All Roles"
            ? allApplicants
            : allApplicants.where((a) => (a['job_title'] ?? 'General') == _selectedRole).toList();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topInset,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RecruiterHeaderStats(),
              SizedBox(height: AppSpacing.md),
              _buildRolePills(allApplicants),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: filteredApplicants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded, size: 44, color: AppColors.primary),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              "Queue cleared for $_selectedRole!",
                              style: AppTypography.bodyMediumBold,
                            ),
                            SizedBox(height: AppSpacing.xs),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedRole = "All Roles";
                                  _currentCandidateIdx = 0;
                                });
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text("View All Roles"),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final safeIdx = _currentCandidateIdx % filteredApplicants.length;
                          final app = filteredApplicants[safeIdx];
                          final name = app['profiles']?['full_name'] ?? 'Unknown Candidate';
                          final role = app['job_title'] ?? 'N/A';
                          final companyName = app['company_name'] ?? 'N/A';
                          final status = app['status'] ?? 'applied';
                          final color = _candidateColors[safeIdx % _candidateColors.length];

                          return Column(
                            children: [
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
                                "Queue: ${safeIdx + 1} / ${filteredApplicants.length}",
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
