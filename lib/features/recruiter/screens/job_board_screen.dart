import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
    final views = (j['view_count'] as int?) ?? 0;
    final applications = await _countApplications(j['title'] ?? '', j['company'] ?? '');
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => JobAnalyticsDialog(
        title: j['title'] ?? 'Job Analytics',
        views: views,
        applications: applications,
      ),
    );
  }

  void _refresh() {
    setState(() {
      _jobsFuture = _fetchJobs();
    });
  }

  Future<void> _openJobForm({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final companyCtrl = TextEditingController(text: existing?['company'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final salaryCtrl = TextEditingController(text: existing?['salary_range'] ?? '');
    final locationCtrl = TextEditingController(text: existing?['location'] ?? '');
    String selectedMode = existing?['mode'] ?? _modes.first;
    String? logoUrl = existing?['logo_url'];
    bool isUploadingLogo = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(existing == null ? "Post New Job" : "Edit Job", style: AppTypography.titleMedium),
                    IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Job Title",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.work_outline, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: companyCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Company",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.business_outlined, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: locationCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Location (e.g. Hyderabad)",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: (logoUrl != null && logoUrl!.isNotEmpty) ? NetworkImage(logoUrl!) : null,
                      child: (logoUrl == null || logoUrl!.isEmpty)
                          ? Icon(Icons.apartment, color: AppColors.textMuted)
                          : null,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isUploadingLogo
                            ? null
                            : () async {
                                final res = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (res == null) return;
                                setSheetState(() => isUploadingLogo = true);
                                try {
                                  final fileName = res.files.single.name;
                                  final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
                                  if (kIsWeb) {
                                    final bytes = res.files.single.bytes!;
                                    await Supabase.instance.client.storage
                                        .from('company-logos')
                                        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
                                  } else {
                                    final file = File(res.files.single.path!);
                                    await Supabase.instance.client.storage
                                        .from('company-logos')
                                        .upload(path, file, fileOptions: const FileOptions(upsert: true));
                                  }
                                  final publicUrl = Supabase.instance.client.storage
                                      .from('company-logos')
                                      .getPublicUrl(path);
                                  setSheetState(() {
                                    logoUrl = publicUrl;
                                    isUploadingLogo = false;
                                  });
                                } catch (e) {
                                  setSheetState(() => isUploadingLogo = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text("Logo upload failed: $e"), backgroundColor: AppColors.error),
                                    );
                                  }
                                }
                              },
                        icon: isUploadingLogo
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload, size: 18),
                        label: Text(isUploadingLogo ? "Uploading..." : "Upload Company Logo"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.description_outlined, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  style: TextStyle(color: AppColors.textPrimary),
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: "Work Mode",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.videocam_outlined, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                  items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setSheetState(() => selectedMode = v ?? _modes.first),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: salaryCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: "Salary Range (e.g. \u20b915L - \u20b922L)",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.currency_rupee, color: Colors.deepOrange, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(existing == null ? "POST JOB" : "SAVE CHANGES"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;
    if (titleCtrl.text.trim().isEmpty || companyCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title and Company are required.")),
        );
      }
      return;
    }

    try {
      final payload = {
        'title': titleCtrl.text.trim(),
        'company': companyCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'mode': selectedMode,
        'location': locationCtrl.text.trim(),
        'salary_range': salaryCtrl.text.trim(),
        'logo_url': logoUrl,
      };

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: const Text("Delete Job"),
        content: Text("Are you sure you want to delete \"${job['title']}\"?"),
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

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('jobs').delete().eq('id', job['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Job deleted"), backgroundColor: AppColors.success),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: AppColors.error),
        );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openJobForm(),
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Post Job", style: TextStyle(color: Colors.white)),
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
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_off_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      "No jobs posted yet. Tap \"Post Job\" to add your first listing.",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              JobBoardHeader(jobCount: jobs.length),
              SizedBox(height: AppSpacing.xl),
              ...jobs.map(
                (j) => JobBoardCard(
                  title: (j['title'] ?? 'N/A').toString(),
                  company: (j['company'] ?? 'N/A').toString(),
                  mode: (j['mode'] ?? 'N/A').toString(),
                  description: j['description']?.toString(),
                  salaryRange: (j['salary_range'] ?? 'N/A').toString(),
                  onAnalytics: () => _showJobAnalytics(j),
                  onEdit: () => _openJobForm(existing: j),
                  onDelete: () => _confirmDelete(j),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
