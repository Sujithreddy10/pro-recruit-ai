import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class JobAnalyticsDialog extends StatelessWidget {
  final String title;
  final int views;
  final int applications;

  const JobAnalyticsDialog({
    super.key,
    required this.title,
    required this.views,
    required this.applications,
  });

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

  @override
  Widget build(BuildContext context) {
    final cr = views > 0 ? (applications / views * 100).toStringAsFixed(1) : '0.0';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Job Analytics", style: AppTypography.titleMedium),
          SizedBox(height: AppSpacing.xs),
          Text(title, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _analyticsRow(Icons.visibility_outlined, "Job Views", views.toString()),
          SizedBox(height: AppSpacing.md),
          _analyticsRow(Icons.description_outlined, "Applications", applications.toString()),
          SizedBox(height: AppSpacing.md),
          _analyticsRow(Icons.percent, "Conversion Rate", "$cr%"),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
      ],
    );
  }
}

class JobBoardHeader extends StatelessWidget {
  final int jobCount;
  final VoidCallback onPostJob;

  const JobBoardHeader({
    super.key,
    required this.jobCount,
    required this.onPostJob,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C2D12), Colors.deepOrange]),
        borderRadius: AppBorderRadius.large,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ACTIVE OPENINGS", style: AppTypography.sectionHeader.copyWith(color: Colors.orange.shade100)),
              SizedBox(height: AppSpacing.xs),
              Text(
                "$jobCount Open Roles",
                style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18),
              ),
              Text("Visible to candidates in real-time", style: AppTypography.caption.copyWith(color: Colors.white70)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onPostJob,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("POST JOB"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class JobBoardCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final Future<int> Function(String title, String company) countApplications;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAnalytics;

  const JobBoardCard({
    super.key,
    required this.job,
    required this.countApplications,
    required this.onEdit,
    required this.onDelete,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = job['logo_url'] as String?;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: (logoUrl != null && logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                child: (logoUrl == null || logoUrl.isEmpty)
                    ? Icon(Icons.business, color: AppColors.textMuted, size: 20)
                    : null,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['title'] ?? 'Untitled', style: AppTypography.bodyMediumBold),
                    Text(
                      "${job['company'] ?? 'Unknown'} \u2022 ${job['location'] ?? 'Remote'}",
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'analytics') onAnalytics();
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'analytics',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 16),
                        SizedBox(width: 8),
                        Text("Analytics"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text("Delete", style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: AppDecorations.pill(Colors.deepOrange),
                child: Text(
                  job['mode'] ?? 'Hybrid',
                  style: AppTypography.captionBold.copyWith(color: Colors.deepOrange),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              if (job['salary_range'] != null)
                Text(
                  job['salary_range'],
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              const Spacer(),
              FutureBuilder<int>(
                future: countApplications(job['title'] ?? '', job['company'] ?? ''),
                builder: (context, appSnap) {
                  final appCount = appSnap.data ?? 0;
                  return Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textMuted),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        "$appCount applied",
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JobFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<String> modes;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const JobFormSheet({
    super.key,
    this.existing,
    required this.modes,
    required this.onSave,
  });

  @override
  State<JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends State<JobFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _locationCtrl;
  late String _selectedMode;
  String? _logoUrl;
  bool _isUploadingLogo = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?['title'] ?? '');
    _companyCtrl = TextEditingController(text: widget.existing?['company'] ?? '');
    _descCtrl = TextEditingController(text: widget.existing?['description'] ?? '');
    _salaryCtrl = TextEditingController(text: widget.existing?['salary_range'] ?? '');
    _locationCtrl = TextEditingController(text: widget.existing?['location'] ?? '');
    _selectedMode = widget.existing?['mode'] ?? widget.modes.first;
    _logoUrl = widget.existing?['logo_url'];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descCtrl.dispose();
    _salaryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return;

    setState(() => _isUploadingLogo = true);
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

      if (mounted) {
        setState(() {
          _logoUrl = publicUrl;
          _isUploadingLogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logo upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _companyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Company are required.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave({
        'title': _titleCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'mode': _selectedMode,
        'location': _locationCtrl.text.trim(),
        'salary_range': _salaryCtrl.text.trim(),
        'logo_url': _logoUrl,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existing == null ? "Post New Job" : "Edit Job", style: AppTypography.titleMedium),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleCtrl,
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
              controller: _companyCtrl,
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
              controller: _locationCtrl,
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
                  backgroundImage: (_logoUrl != null && _logoUrl!.isNotEmpty) ? NetworkImage(_logoUrl!) : null,
                  child: (_logoUrl == null || _logoUrl!.isEmpty)
                      ? Icon(Icons.apartment, color: AppColors.textMuted)
                      : null,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
                    icon: _isUploadingLogo
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload, size: 18),
                    label: Text(_isUploadingLogo ? "Uploading..." : "Upload Company Logo"),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descCtrl,
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
              initialValue: _selectedMode,
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
              items: widget.modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _selectedMode = v ?? widget.modes.first),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: _salaryCtrl,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.existing == null ? "POST JOB" : "SAVE CHANGES"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
