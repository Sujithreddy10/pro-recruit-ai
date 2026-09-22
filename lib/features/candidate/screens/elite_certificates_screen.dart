import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_certificate_widgets.dart';

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
          SnackBar(content: Text("Could not open file: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> cert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteCertificateDialog(title: (cert['title'] ?? '').toString()),
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
    final formData = await showModalBottomSheet<AddCertificateFormData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => const AddCertificateBottomSheet(),
    );

    if (formData == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(formData.file.path!);
      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_${formData.file.name}';

      await Supabase.instance.client.storage
          .from('certificates')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('candidate_certificates').insert({
        'user_id': userId,
        'title': formData.title,
        'issuing_org': formData.issuingOrg,
        'date_earned': formData.dateEarned?.toIso8601String().split('T').first,
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
            return const CertificateEmptyView();
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              CertificateHeaderCard(count: certs.length),
              SizedBox(height: AppSpacing.xl),
              ...certs.map(
                (c) => CertificateItemCard(
                  cert: c,
                  onView: () => _viewCertificate(c['file_path']),
                  onDelete: () => _confirmDelete(c),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
