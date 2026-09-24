import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_pipeline_cards.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class PipelineDashboardTab extends StatefulWidget {
  const PipelineDashboardTab({super.key});

  @override
  State<PipelineDashboardTab> createState() => _PipelineDashboardTabState();
}

class _PipelineDashboardTabState extends State<PipelineDashboardTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  String _selectedRole = "All Roles";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _fetchApplications();
  }

  Future<List<Map<String, dynamic>>> _fetchApplications() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('*, profiles(full_name, resume_path)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No resume uploaded by this candidate.")),
        );
      }
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('resumes')
          .createSignedUrl(resumePath, 60 * 5);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open resume: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateStatus(int id, String newStatus, {bool closeParent = true}) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus, 'status_updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);

      if (mounted) {
        if (closeParent) Navigator.pop(context);
        setState(() {
          _applicationsFuture = _fetchApplications();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showCandidateDetailSheet(Map<String, dynamic> item) {
    final name = item['profiles']?['full_name'] ?? 'Candidate #${item['id']}';
    final job = item['job_title'] ?? 'Role not specified';
    final status = (item['status'] ?? 'applied').toString();
    final resumePath = item['profiles']?['resume_path'] as String?;
    final date = (item['created_at'] ?? '').toString().split('T').first;
    final matchScore = item['match_score'] ?? item['ai_score'] ?? 88;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(ctx).padding.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          Text(job, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "AI Match $matchScore%",
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("Applied $date", style: AppTypography.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Text("DOCUMENT & RESUME", style: AppTypography.sectionHeader),
                SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => _viewResume(resumePath),
                  borderRadius: AppBorderRadius.small,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: AppBorderRadius.small,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          resumePath != null ? Icons.picture_as_pdf : Icons.file_present_outlined,
                          color: resumePath != null ? Colors.redAccent : AppColors.textMuted,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resumePath != null ? "Official Candidate Resume.pdf" : "No resume uploaded",
                                style: AppTypography.bodyMediumBold,
                              ),
                              Text(
                                resumePath != null ? "Tap to open and preview document" : "Applicant did not attach PDF",
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (resumePath != null)
                          const Icon(Icons.open_in_new, size: 18, color: Colors.white60),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text("PIPELINE ACTIONS", style: AppTypography.sectionHeader),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (status != 'shortlisted')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(item['id'], 'shortlisted', closeParent: false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Shortlist"),
                        ),
                      ),
                    if (status != 'shortlisted') const SizedBox(width: 8),
                    if (status != 'offer_sent')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(item['id'], 'offer_sent', closeParent: false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Extend Offer"),
                        ),
                      ),
                    if (status != 'offer_sent') const SizedBox(width: 8),
                    if (status != 'rejected')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(item['id'], 'rejected', closeParent: false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Archive"),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStageCandidates(String stageName, String statusKey, List<Map<String, dynamic>> candidates) {
    final filtered = candidates.where((c) => (c['status'] ?? 'applied') == statusKey).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stageName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            "${filtered.length} candidates in this stage",
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            "No candidates in $stageName",
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final name = item['profiles']?['full_name'] ?? 'Candidate #${item['id']}';
                            final job = item['job_title'] ?? 'Role not specified';
                            final date = (item['created_at'] ?? '').toString().split('T').first;

                            return Material(
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppBorderRadius.small,
                                side: BorderSide(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _showCandidateDetailSheet(item),
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: AppTypography.bodyMediumBold),
                                            Text(job, style: AppTypography.caption),
                                            if (date.isNotEmpty)
                                              Text(
                                                "Applied: $date",
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (item['profiles']?['resume_path'] != null)
                                        IconButton(
                                          icon: const Icon(Icons.description_outlined, size: 20),
                                          color: AppColors.primary,
                                          tooltip: "View Resume",
                                          onPressed: () => _viewResume(item['profiles']?['resume_path']),
                                        ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        onSelected: (targetStatus) => _updateStatus(item['id'], targetStatus),
                                        itemBuilder: (_) => [
                                          if (statusKey != 'shortlisted')
                                            const PopupMenuItem(
                                              value: 'shortlisted',
                                              child: Text('Move to Shortlisted'),
                                            ),
                                          const PopupMenuItem(
                                            value: 'offer_sent',
                                            child: Text('Extend Job Offer'),
                                          ),
                                          if (statusKey != 'applied')
                                            const PopupMenuItem(
                                              value: 'applied',
                                              child: Text('Move to Applied'),
                                            ),
                                          if (statusKey != 'rejected')
                                            const PopupMenuItem(
                                              value: 'rejected',
                                              child: Text('Archive / Reject'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRolePills(List<Map<String, dynamic>> allApplications) {
    final Map<String, int> counts = {"All Roles": allApplications.length};
    for (final app in allApplications) {
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
                  setState(() => _selectedRole = role);
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
      future: _applicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
          );
        }

        final allApps = snapshot.data ?? [];
        final visibleApps = _selectedRole == "All Roles"
            ? allApps
            : allApps.where((a) => (a['job_title'] ?? 'General') == _selectedRole).toList();

        final counts = <String, int>{'applied': 0, 'shortlisted': 0, 'rejected': 0};
        for (final row in visibleApps) {
          final status = (row['status'] as String? ?? 'applied').toLowerCase();
          counts[status] = (counts[status] ?? 0) + 1;
        }

        final total = visibleApps.length;
        double ratio(int v) => total == 0 ? 0 : v / total;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _applicationsFuture = _fetchApplications();
            });
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topInset,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              RecruiterPipelineHeader(
                total: total,
                subtitle: _selectedRole == "All Roles"
                    ? "Real-time candidate status across all roles"
                    : "Status funnel for $_selectedRole",
              ),
              SizedBox(height: AppSpacing.md),
              _buildRolePills(allApps),
              SizedBox(height: AppSpacing.lg),
              RecruiterPipelineStageCard(
                title: "Applied (Awaiting Review)",
                count: "${counts['applied']} Candidates",
                accentColor: AppColors.info,
                progress: ratio(counts['applied']!),
                onTap: () => _showStageCandidates("Applied Candidates", "applied", visibleApps),
              ),
              RecruiterPipelineStageCard(
                title: "Shortlisted",
                count: "${counts['shortlisted']} Candidates",
                accentColor: AppColors.success,
                progress: ratio(counts['shortlisted']!),
                onTap: () => _showStageCandidates("Shortlisted Candidates", "shortlisted", visibleApps),
              ),
              RecruiterPipelineStageCard(
                title: "Rejected / Archived",
                count: "${counts['rejected']} Candidates",
                accentColor: AppColors.error,
                progress: ratio(counts['rejected']!),
                onTap: () => _showStageCandidates("Rejected Candidates", "rejected", visibleApps),
              ),
            ],
          ),
        );
      },
    );
  }
}
