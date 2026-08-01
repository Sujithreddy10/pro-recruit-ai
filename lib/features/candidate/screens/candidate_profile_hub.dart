import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateProfileHub extends StatefulWidget {
  const CandidateProfileHub({super.key});
  @override
  State<CandidateProfileHub> createState() => _CandidateProfileHubState();
}

class _CandidateProfileHubState extends State<CandidateProfileHub> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return {'name': '', 'skills': [], 'projects': []};
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    final skills = await Supabase.instance.client
        .from('candidate_skills')
        .select('id, skill_name, category, proficiency')
        .eq('user_id', userId)
        .order('created_at');

    final projects = await Supabase.instance.client
        .from('candidate_projects')
        .select('id, title, description, tech_tags, project_link')
        .eq('user_id', userId)
        .order('created_at');

    return {
      'name': profile?['full_name'] ?? 'Candidate',
      'skills': List<Map<String, dynamic>>.from(skills),
      'projects': List<Map<String, dynamic>>.from(projects),
    };
  }

  void _refresh() {
    setState(() {
      _profileFuture = _fetchProfileData();
    });
  }

  Color _proficiencyColor(String level) {
    switch (level) {
      case 'Advanced':
        return AppColors.success;
      case 'Pro':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _proficiencyIcon(String level) {
    switch (level) {
      case 'Advanced':
        return Icons.workspace_premium;
      case 'Pro':
        return Icons.verified;
      default:
        return Icons.school;
    }
  }

  Future<void> _addSkillDialog() async {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    String proficiency = 'Beginner';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Add Skill", style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Skill Name (e.g. FastAPI)")),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: "Category (e.g. REST API Development)")),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: proficiency,
                decoration: const InputDecoration(labelText: "Proficiency"),
                items: ['Beginner', 'Pro', 'Advanced']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => proficiency = v ?? 'Beginner'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add")),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('candidate_skills').insert({
          'user_id': userId,
          'skill_name': nameCtrl.text.trim(),
          'category': categoryCtrl.text.trim(),
          'proficiency': proficiency,
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add skill: $e")));
        }
      }
    }
  }

  Future<void> _addProjectDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Add Project", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Project Title")),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: "Tech Tags (comma separated)")),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: "Project Link (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add")),
        ],
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('candidate_projects').insert({
          'user_id': userId,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'tech_tags': tagsCtrl.text.trim(),
          'project_link': linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add project: $e")));
        }
      }
    }
  }

  Future<void> _exportPdf(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final skills = data['skills'] as List<Map<String, dynamic>>;
    final projects = data['projects'] as List<Map<String, dynamic>>;
    final name = data['name'] as String;

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: name),
          pw.SizedBox(height: 16),
          pw.Text("SKILLS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          ...skills.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("${s['skill_name']} — ${s['category'] ?? ''}"),
                    pw.Text(s['proficiency']),
                  ],
                ),
              )),
          pw.SizedBox(height: 20),
          pw.Text("PROJECTS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          ...projects.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(p['title'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(p['description']),
                    pw.Text(p['tech_tags'], style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              )),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${name.replaceAll(' ', '_')}_ATS_Resume.pdf');
    await file.writeAsBytes(bytes);

    if (mounted) {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "My ATS Resume",
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Executive Profile", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final data = snapshot.data!;
          final skills = data['skills'] as List<Map<String, dynamic>>;
          final projects = data['projects'] as List<Map<String, dynamic>>;
          final name = data['name'] as String;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              // --- HERO HEADER ---
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, Colors.indigo.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 28),
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                            SizedBox(width: AppSpacing.xs),
                            Text("HYLO VERIFIED", style: AppTypography.sectionHeader.copyWith(color: Colors.greenAccent, letterSpacing: 1.6)),
                          ]),
                          SizedBox(height: AppSpacing.xs),
                          Text(name, style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20)),
                          SizedBox(height: AppSpacing.xs),
                          Text("${skills.length} skills · ${projects.length} projects", style: AppTypography.caption.copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- SKILLS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.bolt, size: 18, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text("SKILLS", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
                  ]),
                  TextButton.icon(
                    onPressed: _addSkillDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text("Add Skill"),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              if (skills.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No skills added yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else
                ...skills.map((s) {
                  final color = _proficiencyColor(s['proficiency']);
                  return Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: color.withValues(alpha: 0.18)),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: Icon(_proficiencyIcon(s['proficiency']), color: color, size: 18),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['skill_name'], style: AppTypography.bodyMediumBold),
                              if ((s['category'] ?? '').toString().isNotEmpty)
                                Text(s['category'], style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: AppDecorations.pill(color),
                          child: Text(s['proficiency'].toString().toUpperCase(),
                              style: AppTypography.captionBold.copyWith(color: color)),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: AppSpacing.xl),

              // --- PROJECTS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.rocket_launch_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text("FEATURED PROJECTS", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
                  ]),
                  TextButton.icon(
                    onPressed: _addProjectDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text("Add Project"),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              if (projects.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No projects added yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else
                ...projects.map((p) {
                  final tags = (p['tech_tags'] as String? ?? '')
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  return Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade50, AppColors.primary.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.folder_special_outlined, size: 18, color: AppColors.primary),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(p['title'], style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary)),
                          ),
                        ]),
                        SizedBox(height: AppSpacing.sm),
                        Text(p['description'], style: AppTypography.bodySmall),
                        SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: tags
                              .map((t) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(t, style: AppTypography.captionBold.copyWith(color: AppColors.primary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: AppSpacing.xl),

              // --- EXPORT ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  borderRadius: AppBorderRadius.medium,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _exportPdf(data),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text("Export Corporate ATS Resume (PDF)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
