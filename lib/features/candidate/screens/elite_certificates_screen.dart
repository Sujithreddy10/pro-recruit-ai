import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class EliteCertificatesScreen extends StatefulWidget {
  const EliteCertificatesScreen({super.key});
  @override
  State<EliteCertificatesScreen> createState() => _EliteCertificatesScreenState();
}

class _EliteCertificatesScreenState extends State<EliteCertificatesScreen> {
  late Future<List<Map<String, dynamic>>> _certsFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _certsFuture = _fetchCertificates();
  }

  Future<List<Map<String, dynamic>>> _fetchCertificates() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('candidate_certificates')
        .select('id, title, issuing_org, date_earned, file_path')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  void _refresh() {
    setState(() {
      _certsFuture = _fetchCertificates();
    });
  }

  Future<void> _viewCertificate(String filePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('certificates')
          .createSignedUrl(filePath, 60 * 5);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> cert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Delete Certificate?", style: AppTypography.titleMedium),
        content: Text("This will permanently remove \"${cert['title']}\".", style: AppTypography.bodySmall),
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
      await Supabase.instance.client.storage.from('certificates').remove([cert['file_path']]);
      await Supabase.instance.client.from('candidate_certificates').delete().eq('id', cert['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Certificate deleted"), backgroundColor: AppColors.success),
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

  Future<void> _openAddForm() async {
    final titleCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    DateTime? selectedDate;
    PlatformFile? pickedFile;

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
                    Text("Add Certificate", style: AppTypography.titleMedium),
                    IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                SizedBox(height: AppSpacing.sm),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Certificate Title")),
                SizedBox(height: AppSpacing.md),
                TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: "Issuing Organization")),
                SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheetState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: "Date Earned"),
                    child: Text(selectedDate == null
                        ? "Select date"
                        : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (result != null) setSheetState(() => pickedFile = result.files.single);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(pickedFile == null ? "Choose File (PDF/Image)" : pickedFile!.name),
                ),
                SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("UPLOAD CERTIFICATE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;
    if (titleCtrl.text.trim().isEmpty || orgCtrl.text.trim().isEmpty || pickedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title, organization, and file are all required.")),
        );
      }
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile!.path!);
      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';

      await Supabase.instance.client.storage
          .from('certificates')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('candidate_certificates').insert({
        'user_id': userId,
        'title': titleCtrl.text.trim(),
        'issuing_org': orgCtrl.text.trim(),
        'date_earned': selectedDate?.toIso8601String().split('T').first,
        'file_path': storagePath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Certificate added successfully"), backgroundColor: AppColors.success),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Elite Certificates", style: AppTypography.titleMedium.copyWith(color: AppColors.accentAmber)),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.accentAmber),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _openAddForm,
        backgroundColor: AppColors.primaryDark,
        icon: _isUploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add, color: Colors.white),
        label: Text(_isUploading ? "Uploading..." : "Add Certificate", style: const TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _certsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final certs = snapshot.data ?? [];

          if (certs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
                    SizedBox(height: AppSpacing.md),
                    Text("No certificates uploaded yet. Tap \"Add Certificate\" to add your first one.",
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
                  gradient: LinearGradient(colors: [const Color(0xFF78350F), AppColors.accentAmber]),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("YOUR CREDENTIALS", style: AppTypography.sectionHeader.copyWith(color: Colors.amber.shade100)),
                    SizedBox(height: AppSpacing.xs),
                    Text("${certs.length} Certificates Uploaded", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18)),
                    Text("Real, verifiable credentials you've earned", style: AppTypography.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              ...certs.map((c) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: Icon(Icons.workspace_premium, color: AppColors.accentAmber, size: 20),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['title'] ?? 'N/A', style: AppTypography.bodyMediumBold),
                              Text(c['issuing_org'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              if (c['date_earned'] != null)
                                Text("Earned: ${c['date_earned']}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.visibility_outlined, color: AppColors.info, size: 20),
                          onPressed: () => _viewCertificate(c['file_path']),
                          tooltip: "View",
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () => _confirmDelete(c),
                          tooltip: "Delete",
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
