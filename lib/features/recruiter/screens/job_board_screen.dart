import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

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
        .select('id, title, company, description, mode, salary_range, logo_url, view_count')
        .order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> _countApplications(String title, String company) async {
    try {
      final res = await Supabase.instance.client
          .from('applications')
          .select()
          .eq('job_title', title)
          .eq('company_name', company)
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _showJobAnalytics(Map<String, dynamic> j) async {
    final views = (j['view_count'] as int?) ?? 0;
    final applications = await _countApplications(j['title'] ?? '', j['company'] ?? '');
    final hasViews = views > 0 && applications <= views;
    final conversion = hasViews ? (applications / views * 100) : null;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text(j['title'] ?? 'Job Analytics', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _analyticsRow(Icons.visibility_outlined, "Views", "$views"),
            SizedBox(height: AppSpacing.sm),
            _analyticsRow(Icons.people_outline, "Applications", "$applications"),
            SizedBox(height: AppSpacing.sm),
            _analyticsRow(Icons.trending_up, "Conversion Rate", hasViews ? "${conversion!.toStringAsFixed(1)}%" : "N/A"),
            if (!hasViews) ...[
              SizedBox(height: AppSpacing.sm),
              Text("View tracking started recently — older applications may predate it.",
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _analyticsRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepOrange),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.bodyMediumBold),
      ],
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
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (result == null) return;
                                setSheetState(() => isUploadingLogo = true);
                                final session = Supabase.instance.client.auth.currentSession;
                                debugPrint("LOGO_DEBUG userId=${Supabase.instance.client.auth.currentUser?.id} hasSession=${session != null} tokenExpired=${session?.isExpired}");
                                try {
                                  final fileName = result.files.single.name;
                                  final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
                                  if (kIsWeb) {
                                    final bytes = result.files.single.bytes!;
                                    await Supabase.instance.client.storage
                                        .from('company-logos')
                                        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
                                  } else {
                                    final file = File(result.files.single.path!);
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
                                  debugPrint("LOGO_DEBUG exception runtimeType=${e.runtimeType}");
                                  if (e is StorageException) {
                                    debugPrint("LOGO_DEBUG StorageException statusCode=${e.statusCode} error=${e.error} message=${e.message}");
                                  } else {
                                    debugPrint("LOGO_DEBUG raw=$e");
                                  }
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Delete Job?", style: AppTypography.titleMedium),
        content: Text(
          "This will permanently remove \"${job['title']}\" at ${job['company']}. Existing applications referencing this job will not be affected.",
          style: AppTypography.bodySmall,
        ),
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
          SnackBar(content: Text("Job deleted"), backgroundColor: AppColors.success),
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
                    Text("No jobs posted yet. Tap \"Post Job\" to add your first listing.",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C2D12), Colors.deepOrange]),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("JOB BOARD MANAGEMENT", style: AppTypography.sectionHeader.copyWith(color: Colors.orange.shade100)),
                    SizedBox(height: AppSpacing.xs),
                    Text("${jobs.length} Active Postings", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18)),
                    Text("Manage all open roles from one place", style: AppTypography.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              ...jobs.map((j) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.15)),
                      boxShadow: [BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                              child: const Icon(Icons.business_center_outlined, color: Colors.deepOrange, size: 20),
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
                              decoration: AppDecorations.pill(Colors.deepOrange),
                              child: Text(j['mode'] ?? 'N/A', style: AppTypography.captionBold.copyWith(color: Colors.deepOrange)),
                            ),
                          ],
                        ),
                        if ((j['description'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: AppSpacing.md),
                          Text(j['description'], style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                              child: Text(j['salary_range'] ?? 'N/A', style: AppTypography.bodySmallBold.copyWith(color: AppColors.success)),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.bar_chart_outlined, color: Colors.deepOrange, size: 16),
                                  onPressed: () => _showJobAnalytics(j),
                                  tooltip: "Analytics",
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.edit_outlined, color: AppColors.info, size: 16),
                                  onPressed: () => _openJobForm(existing: j),
                                  tooltip: "Edit",
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                                  onPressed: () => _confirmDelete(j),
                                  tooltip: "Delete",
                                ),
                              ],
                            ),
                          ],
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
