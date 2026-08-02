import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

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
    final future = _load();
    setState(() {
      _resumesFuture = future;
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final resumes = await Supabase.instance.client
        .from('candidate_resumes')
        .select()
        .eq('candidate_id', userId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(resumes);
  }

  Future<void> _uploadResume(List<Map<String, dynamic>> resumes) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (resumes.length >= _maxResumes) {
      _showLimitReachedDialog();
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    setState(() => _isUploading = true);
    try {
      await Supabase.instance.client.storage
          .from('resumes')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('candidate_resumes').insert({
        'candidate_id': userId,
        'storage_path': storagePath,
        'file_name': fileName,
        'label': fileName.replaceAll('.pdf', '').replaceAll('_', ' '),
        'is_primary': resumes.isEmpty,
      });
      () async {
        try {
          await Supabase.instance.client.functions.invoke('parse-resume', body: {'storagePath': storagePath});
        } catch (e) {
          debugPrint("parse-resume failed: $e");
        }
      }();

      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Resume uploaded"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  Future<void> _setPrimary(Map<String, dynamic> resume) async {
    if (resume['is_primary'] == true) return;
    try {
      await Supabase.instance.client
          .from('candidate_resumes')
          .update({'is_primary': true}).eq('id', resume['id']);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't set primary: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _renameLabel(Map<String, dynamic> resume) async {
    final controller = TextEditingController(text: resume['label']);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Rename Resume"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. Software Engineer Resume"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (newLabel == null || newLabel.isEmpty) return;
    await Supabase.instance.client
        .from('candidate_resumes')
        .update({'label': newLabel}).eq('id', resume['id']);
    _reload();
  }

  Future<void> _deleteResume(Map<String, dynamic> resume) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Resume?"),
        content: Text("\"${resume['label']}\" will be permanently removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete"),
          ),
        ],
      ),
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

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Resume Slot Limit Reached"),
        content: const Text(
          "You can store up to 3 resumes at a time. Delete one you no longer need to upload a new version.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () => Navigator.pop(c),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
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
                Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppBorderRadius.large,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: Colors.tealAccent, size: 32),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("YOUR VAULT", style: AppTypography.sectionHeader.copyWith(color: Colors.white60, letterSpacing: 2)),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              "${resumes.length} / $_maxResumes resumes",
                              style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              "Tailor a resume per role and switch your primary anytime",
                              style: AppTypography.caption.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                if (resumes.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          "No resumes yet. Upload your first one below.",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  ...resumes.map((r) => _resumeCard(r)),
                SizedBox(height: AppSpacing.lg),
                _uploadButton(resumes, atLimit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _resumeCard(Map<String, dynamic> resume) {
    final isPrimary = resume['is_primary'] == true;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.large,
        border: Border.all(color: isPrimary ? const Color(0xFF0F766E) : AppColors.border, width: isPrimary ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: AppBorderRadius.small,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F766E)),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        resume['label'] ?? resume['file_name'] ?? 'Resume',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("PRIMARY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  resume['file_name'] ?? '',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: (action) {
              if (action == 'primary') _setPrimary(resume);
              if (action == 'rename') _renameLabel(resume);
              if (action == 'delete') _deleteResume(resume);
            },
            itemBuilder: (c) => [
              if (!isPrimary) const PopupMenuItem(value: 'primary', child: Text("Set as Primary")),
              const PopupMenuItem(value: 'rename', child: Text("Rename")),
              const PopupMenuItem(value: 'delete', child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploadButton(List<Map<String, dynamic>> resumes, bool atLimit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : () => _uploadResume(resumes),
        style: ElevatedButton.styleFrom(
          backgroundColor: atLimit ? AppColors.textMuted : const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
        ),
        icon: _isUploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(atLimit ? Icons.lock_outline : Icons.upload_file_rounded),
        label: Text(atLimit ? "Maximum Resumes Reached (3/3)" : "Upload Resume (PDF)"),
      ),
    );
  }
}
