import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class EliteProfileHub extends StatefulWidget {
  const EliteProfileHub({super.key});
  @override
  State<EliteProfileHub> createState() => _EliteProfileHubState();
}

class _EliteProfileHubState extends State<EliteProfileHub> {
  bool _isActivelySearching = true;

  Future<void> _toggleActiveSearching(bool val) async {
    setState(() => _isActivelySearching = val);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'is_actively_searching': val,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating active search status: $e');
    }
  }

  Future<void> _saveSectionFields(String title, Map<String, String> values) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final key = title.toLowerCase().replaceAll(' ', '_');
    try {
      final currentMetadata = (_profileData['metadata'] as Map<String, dynamic>?) ?? {};
      final updated = Map<String, dynamic>.from(currentMetadata)..[key] = values;
      await Supabase.instance.client.from('profiles').update({
        'metadata': updated,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title updated successfully!"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update $title: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  bool _isUploading = false;
  String? _resumeFileName;
  String? _resumePath;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadResumeStatus();
    _loadProfileData();
  }
  Future<void> _loadProfileData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone, city, work_status, availability, professional_summary')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _profileData = data);
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }
  String get _candidateEmail => Supabase.instance.client.auth.currentUser?.email ?? 'Not set';
  String get _basicDetailsSubtitle {
    final parts = <String>[];
    if ((_profileData['work_status'] ?? '').toString().isNotEmpty) parts.add(_profileData['work_status'].toString());
    if ((_profileData['city'] ?? '').toString().isNotEmpty) parts.add(_profileData['city'].toString());
    if ((_profileData['phone'] ?? '').toString().isNotEmpty) parts.add(_profileData['phone'].toString());
    parts.add(_candidateEmail);
    return parts.join(', ');
  }
  Future<void> _editBasicDetails() async {
    final workStatusCtrl = TextEditingController(text: _profileData['work_status'] ?? '');
    final cityCtrl = TextEditingController(text: _profileData['city'] ?? '');
    final phoneCtrl = TextEditingController(text: _profileData['phone'] ?? '');
    final availabilityCtrl = TextEditingController(text: _profileData['availability'] ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Update Basic Details", style: AppTypography.titleMedium),
            IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
          ]),
          const Divider(),
          SizedBox(height: AppSpacing.sm),
          TextField(
            enabled: false,
            controller: TextEditingController(text: _candidateEmail),
            decoration: InputDecoration(labelText: "Email ID (login email)", border: OutlineInputBorder(borderRadius: AppBorderRadius.small), filled: true, fillColor: AppColors.surfaceVariant),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(controller: workStatusCtrl, decoration: InputDecoration(labelText: "Work Status", border: OutlineInputBorder(borderRadius: AppBorderRadius.small))),
          SizedBox(height: AppSpacing.md),
          TextField(controller: cityCtrl, decoration: InputDecoration(labelText: "Current City", border: OutlineInputBorder(borderRadius: AppBorderRadius.small))),
          SizedBox(height: AppSpacing.md),
          TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(borderRadius: AppBorderRadius.small))),
          SizedBox(height: AppSpacing.md),
          TextField(controller: availabilityCtrl, decoration: InputDecoration(labelText: "Availability to Join", border: OutlineInputBorder(borderRadius: AppBorderRadius.small))),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) return;
              try {
                await Supabase.instance.client.from('profiles').update({
                  'work_status': workStatusCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'availability': availabilityCtrl.text.trim(),
                }).eq('id', userId);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text("SAVE CHANGES"),
          ),
        ]),
      ),
    );
    if (saved == true) {
      _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Basic details updated!"), backgroundColor: AppColors.success));
      }
    }
  }
  Future<void> _editProfileSummary() async {
    final summaryCtrl = TextEditingController(text: _profileData['professional_summary'] ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Update Professional Summary", style: AppTypography.titleMedium),
            IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
          ]),
          const Divider(),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: summaryCtrl,
            maxLines: 5,
            decoration: InputDecoration(labelText: "Professional Summary", hintText: "2-3 sentences about your experience and strengths", border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
          ),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) return;
              try {
                await Supabase.instance.client.from('profiles').update({
                  'professional_summary': summaryCtrl.text.trim(),
                }).eq('id', userId);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text("SAVE CHANGES"),
          ),
        ]),
      ),
    );
    if (saved == true) {
      _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Summary updated!"), backgroundColor: AppColors.success));
      }
    }
  }

  Future<void> _loadResumeStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('resume_path')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null && data['resume_path'] != null) {
        setState(() {
          _resumePath = data['resume_path'];
          _resumeFileName = _resumePath!.split('/').last;
        });
      }
    } catch (e) {
      debugPrint('Error loading resume status: $e');
    }
  }

  Future<void> _pickAndUploadResume() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
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
    final storagePath = '$userId/$fileName';

    setState(() => _isUploading = true);

    try {
      await Supabase.instance.client.storage
          .from('resumes')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('profiles').update({
        'resume_path': storagePath,
        'resume_uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      () async {
        try {
          await Supabase.instance.client.functions.invoke('parse-resume', body: {'storagePath': storagePath});
        } catch (e) {
          debugPrint("parse-resume failed: $e");
        }
      }();

      if (mounted) {
        setState(() {
          _resumePath = storagePath;
          _resumeFileName = fileName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resume uploaded successfully!"), backgroundColor: AppColors.success),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Update Profile", style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          _buildActiveStatus(),
          SizedBox(height: AppSpacing.xl),
          _sectionHeader("BASIC DETAILS"),
          _naukriCard(
              "Basic Details",
              Icons.person_outline,
              _basicDetailsSubtitle,
              AppColors.info,
              _editBasicDetails,
              trailingIcon: Icons.edit_outlined),
          _sectionHeader("RESOURCES"),
          _naukriCard(
              "Export ATS Resume (PDF)",
              Icons.picture_as_pdf_outlined,
              "Generate & share corporate ATS resume",
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CandidateProfileHub()),
                );
              }),
          _naukriCard(
              "Resume",
              Icons.description_outlined,
              _isUploading ? "Uploading..." : (_resumeFileName ?? "No resume uploaded yet"),
              AppColors.success,
              _isUploading ? () {} : _pickAndUploadResume),
          _naukriCard("Video Profile", Icons.videocam_outlined, "AI Simulation Pitch", Colors.purple,
              () => _showUpdateLogic("Video Profile", ["Record AI Pitch", "Upload Video"])),
          _sectionHeader("PROFESSIONAL SUMMARY"),
          _naukriCard(
              "Profile Summary",
              Icons.history_edu,
              (_profileData['professional_summary'] ?? '').toString().isNotEmpty
                  ? _profileData['professional_summary'].toString()
                  : "Tap to add your professional summary",
              AppColors.warning,
              _editProfileSummary,
              trailingIcon: Icons.edit_outlined),
          _naukriCard("Key Skills", Icons.bolt, "Flutter, Dart, Firebase, SOLID", Colors.deepOrange,
              () => _showUpdateLogic("Key Skills", ["Add Skills", "Delete Skills"])),
          _sectionHeader("EXPERIENCE & ACADEMICS"),
          _naukriCard("Employment", Icons.business_center_outlined, "Senior Dev @ Tech Hub", Colors.indigo,
              () => _showUpdateLogic("Employment", ["Company Name", "Designation", "Joining Date"])),
          _naukriCard("Projects", Icons.account_tree_outlined, "Fintech App, E-com Engine", Colors.teal,
              () => _showUpdateLogic("Projects", ["Project Title", "Role", "Description"])),
          _naukriCard("IT Skills", Icons.terminal, "Git, Docker, Bloc, CI/CD, JIRA", Colors.blueGrey,
              () => _showUpdateLogic("IT Skills", ["Software Skills"])),
          _naukriCard("Education", Icons.school_outlined, "B.Tech Computer Science", Colors.brown,
              () => _showUpdateLogic("Education", ["University", "Year of Passing"])),
          _naukriCard("Accomplishments", Icons.emoji_events_outlined, "Certificates & Awards", AppColors.accentAmber,
              () => _showUpdateLogic("Accomplishments", ["Awards", "Online Certifications"])),
          _sectionHeader("PERSONAL & CAREER"),
          _naukriCard(
              "Personal Details",
              Icons.face,
              "DOB, Gender, Home Address",
              AppColors.textMuted,
              () => _showUpdateLogic("Personal Details", ["Date of Birth", "Permanent Address"])),
          _naukriCard(
              "Diversity & Inclusion",
              Icons.diversity_3_outlined,
              "Workplace Preferences",
              Colors.pink,
              () => _showUpdateLogic("Diversity", ["Gender Pref", "Specially Abled Status"])),
          _naukriSection("Languages", Icons.translate, "English, Hindi, Telugu", Colors.cyan),
          _naukriSection("Career Preferences", Icons.star_border, "Remote, Bangalore, 30LPA+", AppColors.info),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildActiveStatus() => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Row(children: [
          const CircleAvatar(
              radius: 25, backgroundColor: Colors.greenAccent, child: Icon(Icons.bolt, color: Colors.white)),
          SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Actively searching jobs", style: AppTypography.bodyMediumBold.copyWith(color: AppColors.success)),
            Text("Profile visibility: High", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ])),
          Switch(value: _isActivelySearching, onChanged: _toggleActiveSearching, activeThumbColor: AppColors.success),
        ]),
      );

  Widget _sectionHeader(String t) => Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(t, style: AppTypography.sectionHeader));

  Widget _naukriCard(String title, IconData icon, String sub, Color color, VoidCallback onTap, {IconData trailingIcon = Icons.add_circle_outline}) => Card(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        elevation: 0.2,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        child: ListTile(
          onTap: onTap,
          leading: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
              child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: AppTypography.bodyMediumBold),
          subtitle: Text(sub, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          trailing: Icon(trailingIcon, color: AppColors.info, size: 20),
        ),
      );

  Widget _naukriSection(String title, IconData icon, String subtitle, Color color) =>
      _naukriCard(title, icon, subtitle, color, () => _showUpdateLogic(title, ["Update $title"]));

  void _showUpdateLogic(String title, List<String> fields) {
    final controllers = {for (var f in fields) f: TextEditingController()};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Update $title", style: AppTypography.titleMedium),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))
          ]),
          const Divider(),
          SizedBox(height: AppSpacing.sm),
          ...fields.map((f) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: TextField(
                  controller: controllers[f],
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: f,
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                  ),
                ),
              )),
          SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () async {
              final data = {for (var e in controllers.entries) e.key: e.value.text.trim()};
              Navigator.pop(ctx);
              await _saveSectionFields(title, data);
            },
            child: const Text("SAVE CHANGES"),
          ),
        ]),
      ),
    );
  }
}
