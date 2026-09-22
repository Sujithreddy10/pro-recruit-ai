import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/job_board_widgets.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});
  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  static const _modes = ['Hybrid', 'Remote', 'On-site'];

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    final data = await Supabase.instance.client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> _countApplications(String title, String company) async {
    try {
      final res = await Supabase.instance.client
          .from('applications')
          .select('id')
          .eq('job_title', title)
          .eq('company_name', company);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showJobAnalytics(Map<String, dynamic> j) async {
    final title = j['title'] ?? 'Untitled';
    final company = j['company'] ?? 'Unknown';
    final views = (j['views'] as int?) ?? 0;
    final apps = await _countApplications(title, company);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => JobAnalyticsDialog(
        title: "$title \u2022 $company",
        views: views,
        applications: apps,
      ),
    );
  }

  void _refresh() {
    setState(() {
      _jobsFuture = _fetchJobs();
    });
  }

  Future<void> _openJobForm({Map<String, dynamic>? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => JobFormSheet(
        existing: existing,
        modes: _modes,
        onSave: (payload) async {
          if (existing == null) {
            final insertPayload = {
              ...payload,
              'recruiter_id': Supabase.instance.client.auth.currentUser?.id,
            };
            await Supabase.instance.client.from('jobs').insert(insertPayload);
          } else {
            await Supabase.instance.client.from('jobs').update(payload).eq('id', existing['id']);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existing == null ? "Job posted successfully" : "Job updated successfully"),
                backgroundColor: AppColors.success,
              ),
            );
            _refresh();
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: const Text("Delete Job Opening?"),
        content: Text("Are you sure you want to remove '${job['title']}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('jobs').delete().eq('id', job['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Job deleted")),
          );
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Job Board", style: AppTypography.titleMedium.copyWith(color: Colors.deepOrange)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
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

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              JobBoardHeader(jobCount: jobs.length, onPostJob: () => _openJobForm()),
              SizedBox(height: AppSpacing.xl),
              Text("POSTED ROLES", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (jobs.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: AppDecorations.card(),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.work_off_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          "No jobs posted yet.",
                          style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textMuted),
                        ),
                        Text(
                          "Click '+ POST JOB' to publish your first role.",
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...jobs.map(
                  (j) => JobBoardCard(
                    job: j,
                    countApplications: _countApplications,
                    onEdit: () => _openJobForm(existing: j),
                    onDelete: () => _confirmDelete(j),
                    onAnalytics: () => _showJobAnalytics(j),
                  ),
                ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }
}
