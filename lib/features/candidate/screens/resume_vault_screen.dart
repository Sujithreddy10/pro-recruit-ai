import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_vault_widgets.dart';

class ResumeVaultScreen extends StatefulWidget {
  const ResumeVaultScreen({super.key});

  @override
  State<ResumeVaultScreen> createState() => _ResumeVaultScreenState();
}

class _ResumeVaultScreenState extends State<ResumeVaultScreen> {
  static const int _maxResumes = 3;
  late Future<List<Map<String, dynamic>>> _resumesFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _resumesFuture = _load();
  }

  void _reload() {
    setState(() {
      _resumesFuture = _load();
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await Supabase.instance.client
        .from('candidate_resumes')
        .select()
        .eq('user_id', userId)
        .order('is_primary', ascending: false)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _uploadResume(List<Map<String, dynamic>> resumes) async {
    if (resumes.length >= _maxResumes) {
      showDialog(context: context, builder: (c) => const ResumeLimitDialog());
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/${timestamp}_$fileName';

    setState(() => _isUploading = true);
    try {
      await Supabase.instance.client.storage
          .from('resumes')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      final isFirst = resumes.isEmpty;
      await Supabase.instance.client.from('candidate_resumes').insert({
        'user_id': userId,
        'label': fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
        'file_name': fileName,
        'storage_path': storagePath,
        'is_primary': isFirst,
      });

      if (isFirst) {
        await Supabase.instance.client.from('profiles').update({'resume_path': storagePath}).eq('id', userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resume uploaded successfully!"), backgroundColor: Color(0xFF0F766E)),
        );
      }
      _reload();
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

  Future<void> _setPrimary(Map<String, dynamic> resume) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_resumes').update({'is_primary': false}).eq('user_id', userId);
      await Supabase.instance.client.from('candidate_resumes').update({'is_primary': true}).eq('id', resume['id']);
      await Supabase.instance.client.from('profiles').update({'resume_path': resume['storage_path']}).eq('id', userId);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not set primary: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _renameLabel(Map<String, dynamic> resume) async {
    final controller = TextEditingController(text: resume['label']);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (c) => RenameResumeDialog(controller: controller),
    );
    if (newLabel == null || newLabel.isEmpty) return;
    await Supabase.instance.client.from('candidate_resumes').update({'label': newLabel}).eq('id', resume['id']);
    _reload();
  }

  Future<void> _deleteResume(Map<String, dynamic> resume) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => DeleteResumeDialog(label: (resume['label'] ?? 'Resume').toString()),
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client.storage.from('resumes').remove([resume['storage_path']]);
      await Supabase.instance.client.from('candidate_resumes').delete().eq('id', resume['id']);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't delete: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Resume Vault", style: AppTypography.titleMedium.copyWith(color: const Color(0xFF0F766E))),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Color(0xFF0F766E)),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _resumesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final resumes = snapshot.data ?? [];
          final atLimit = resumes.length >= _maxResumes;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.lg),
              children: [
                ResumeVaultHeader(count: resumes.length, max: _maxResumes),
                SizedBox(height: AppSpacing.xl),
                if (resumes.isEmpty)
                  const ResumeVaultEmptyView()
                else
                  ...resumes.map(
                    (r) => ResumeVaultCard(
                      resume: r,
                      onSetPrimary: () => _setPrimary(r),
                      onRename: () => _renameLabel(r),
                      onDelete: () => _deleteResume(r),
                    ),
                  ),
                SizedBox(height: AppSpacing.lg),
                ResumeVaultUploadButton(
                  atLimit: atLimit,
                  isUploading: _isUploading,
                  onPressed: atLimit
                      ? () => showDialog(context: context, builder: (c) => const ResumeLimitDialog())
                      : () => _uploadResume(resumes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
