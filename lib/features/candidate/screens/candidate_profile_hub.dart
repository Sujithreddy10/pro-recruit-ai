import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_profile_hub_widgets.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_profile_hub_modals.dart';

class CandidateProfileHub extends StatefulWidget {
  const CandidateProfileHub({super.key});

  @override
  State<CandidateProfileHub> createState() => _CandidateProfileHubState();
}

class _CandidateProfileHubState extends State<CandidateProfileHub> {
  late Future<Map<String, dynamic>> _profileFuture;
  bool _isUploadingResume = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  String get _candidateEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? 'Not set';

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return {
        'name': '',
        'phone': '',
        'city': '',
        'work_status': '',
        'availability': '',
        'professional_summary': '',
        'resume_path': null,
        'preferred_work_mode': '',
        'preferred_location': '',
        'expected_salary': '',
        'identity_status': null,
        'skills': [],
        'projects': [],
        'employment': [],
        'education': [],
        'accomplishments': [],
        'languages': [],
      };
    }
    final profile = await Supabase.instance.client
        .from('profiles')
        .select(
            'full_name, phone, city, work_status, availability, professional_summary, resume_path, preferred_work_mode, preferred_location, expected_salary')
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
    final employment = await Supabase.instance.client
        .from('candidate_employment')
        .select(
            'id, company_name, designation, start_date, end_date, is_current, description')
        .eq('user_id', userId)
        .order('created_at');
    final education = await Supabase.instance.client
        .from('candidate_education')
        .select('id, degree, institution, year_of_passing, grade')
        .eq('user_id', userId)
        .order('created_at');
    final accomplishments = await Supabase.instance.client
        .from('candidate_accomplishments')
        .select('id, title, type, description, date_achieved')
        .eq('user_id', userId)
        .order('created_at');
    final languages = await Supabase.instance.client
        .from('candidate_languages')
        .select('id, language_name, proficiency')
        .eq('user_id', userId)
        .order('created_at');
    final identityRows = await Supabase.instance.client
        .from('identity_verifications')
        .select('status')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
    final identityStatus = identityRows.isNotEmpty
        ? identityRows.first['status'] as String?
        : null;
    return {
      'name': profile?['full_name'] ?? 'Candidate',
      'phone': profile?['phone'] ?? '',
      'city': profile?['city'] ?? '',
      'work_status': profile?['work_status'] ?? '',
      'availability': profile?['availability'] ?? '',
      'professional_summary': profile?['professional_summary'] ?? '',
      'resume_path': profile?['resume_path'],
      'identity_status': identityStatus,
      'preferred_work_mode': profile?['preferred_work_mode'] ?? '',
      'preferred_location': profile?['preferred_location'] ?? '',
      'expected_salary': profile?['expected_salary'] ?? '',
      'skills': List<Map<String, dynamic>>.from(skills),
      'projects': List<Map<String, dynamic>>.from(projects),
      'employment': List<Map<String, dynamic>>.from(employment),
      'education': List<Map<String, dynamic>>.from(education),
      'accomplishments': List<Map<String, dynamic>>.from(accomplishments),
      'languages': List<Map<String, dynamic>>.from(languages),
    };
  }

  void _refresh() {
    setState(() {
      _profileFuture = _fetchProfileData();
    });
  }

  String? _pendingVerificationSessionId;
  Future<void> _startIdentityVerification() async {
    try {
      final initRes = await Supabase.instance.client.functions
          .invoke('identity-verify-init');
      if (initRes.status != 200 ||
          initRes.data == null ||
          initRes.data['authorization_url'] == null) {
        throw Exception(
            initRes.data?['error'] ?? 'Could not start verification');
      }
      final sessionId = initRes.data['session_id'] as String;
      final authUrl = initRes.data['authorization_url'] as String;

      setState(() => _pendingVerificationSessionId = sessionId);

      final launched = await launchUrl(Uri.parse(authUrl),
          mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not open verification link');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Complete verification in your browser, then come back and tap CHECK STATUS.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Verification failed: $e"),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    final sessionId = _pendingVerificationSessionId;
    if (sessionId == null) return;
    try {
      final finalizeRes = await Supabase.instance.client.functions.invoke(
        'identity-verify-finalize',
        body: {'session_id': sessionId},
      );
      final verified = finalizeRes.data?['verified'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verified
                ? "Identity verified successfully!"
                : "Not verified yet -- finish the steps in your browser, then try again."),
            backgroundColor: verified ? AppColors.success : AppColors.error,
          ),
        );
      }
      if (verified) {
        setState(() => _pendingVerificationSessionId = null);
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Could not check status: $e"),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _proficiencyColor(String level) {
    switch (level) {
      case 'Advanced':
      case 'Fluent':
      case 'Native':
        return AppColors.success;
      case 'Pro':
      case 'Conversational':
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

  // ---------- BASIC DETAILS ----------
  Future<void> _editBasicDetails(Map<String, dynamic> data) async {
    final payload = await ProfileModals.showBasicDetails(context, data, _candidateEmail);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('profiles').update(payload).eq('id', userId);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  // ---------- PROFESSIONAL SUMMARY ----------
  Future<void> _editSummary(Map<String, dynamic> data) async {
    final summary = await ProfileModals.showEditSummary(context, data);
    if (summary == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({'professional_summary': summary}).eq('id', userId);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  // ---------- CAREER PREFERENCES ----------
  Future<void> _editCareerPreferences(Map<String, dynamic> data) async {
    final payload = await ProfileModals.showCareerPreferences(context, data);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('profiles').update(payload).eq('id', userId);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  // ---------- SKILLS ----------
  Future<void> _addSkillDialog() async {
    final payload = await ProfileModals.showAddOrEditSkill(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_skills').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add skill: $e")));
    }
  }

  Future<void> _editSkillDialog(Map<String, dynamic> item) async {
    final payload = await ProfileModals.showAddOrEditSkill(context, item: item);
    if (payload == null) return;
    try {
      await Supabase.instance.client.from('candidate_skills').update(payload).eq('id', item['id']);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  // ---------- PROJECTS ----------
  Future<void> _addProjectDialog() async {
    final payload = await ProfileModals.showAddOrEditProject(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_projects').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add project: $e")));
    }
  }

  Future<void> _editProjectDialog(Map<String, dynamic> item) async {
    final payload = await ProfileModals.showAddOrEditProject(context, item: item);
    if (payload == null) return;
    try {
      await Supabase.instance.client.from('candidate_projects').update(payload).eq('id', item['id']);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  // ---------- EMPLOYMENT ----------
  Future<void> _addEmploymentDialog() async {
    final payload = await ProfileModals.showAddOrEditEmployment(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_employment').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add: $e")));
    }
  }

  Future<void> _deleteEmployment(String id) async {
    try {
      await Supabase.instance.client.from('candidate_employment').delete().eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  Future<void> _editEmploymentDialog(Map<String, dynamic> item) async {
    final payload = await ProfileModals.showAddOrEditEmployment(context, item: item);
    if (payload == null) return;
    try {
      await Supabase.instance.client.from('candidate_employment').update(payload).eq('id', item['id']);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  // ---------- EDUCATION ----------
  Future<void> _addEducationDialog() async {
    final payload = await ProfileModals.showAddOrEditEducation(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_education').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add: $e")));
    }
  }

  Future<void> _deleteEducation(String id) async {
    try {
      await Supabase.instance.client.from('candidate_education').delete().eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  Future<void> _editEducationDialog(Map<String, dynamic> item) async {
    final payload = await ProfileModals.showAddOrEditEducation(context, item: item);
    if (payload == null) return;
    try {
      await Supabase.instance.client.from('candidate_education').update(payload).eq('id', item['id']);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  // ---------- ACCOMPLISHMENTS ----------
  Future<void> _addAccomplishmentDialog() async {
    final payload = await ProfileModals.showAddOrEditAccomplishment(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_accomplishments').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add: $e")));
    }
  }

  Future<void> _deleteAccomplishment(String id) async {
    try {
      await Supabase.instance.client.from('candidate_accomplishments').delete().eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  Future<void> _editAccomplishmentDialog(Map<String, dynamic> item) async {
    final payload = await ProfileModals.showAddOrEditAccomplishment(context, item: item);
    if (payload == null) return;
    try {
      await Supabase.instance.client.from('candidate_accomplishments').update(payload).eq('id', item['id']);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  // ---------- LANGUAGES ----------
  Future<void> _addLanguageDialog() async {
    final payload = await ProfileModals.showAddLanguage(context);
    if (payload == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('candidate_languages').insert({
        'user_id': userId,
        ...payload,
      });
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add: $e")));
    }
  }

  Future<void> _deleteLanguage(String id) async {
    try {
      await Supabase.instance.client.from('candidate_languages').delete().eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  // ---------- RESUME ----------
  Future<void> _pickAndUploadResume() async {
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
    final storagePath = '$userId/$fileName';
    setState(() => _isUploadingResume = true);
    try {
      await Supabase.instance.client.storage.from('resumes').upload(
          storagePath, file,
          fileOptions: const FileOptions(upsert: true));
      await Supabase.instance.client.from('profiles').update({
        'resume_path': storagePath,
        'resume_uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      () async {
        try {
          await Supabase.instance.client.functions
              .invoke('parse-resume', body: {'storagePath': storagePath});
        } catch (e) {
          debugPrint("parse-resume failed: $e");
        }
      }();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Resume uploaded successfully!"),
              backgroundColor: AppColors.success),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Upload failed: $e"),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingResume = false);
    }
  }

  // ---------- PDF EXPORT ----------
  Future<void> _exportPdf(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final skills = data['skills'] as List<Map<String, dynamic>>;
    final projects = data['projects'] as List<Map<String, dynamic>>;
    final employment = data['employment'] as List<Map<String, dynamic>>;
    final education = data['education'] as List<Map<String, dynamic>>;
    final accomplishments =
        data['accomplishments'] as List<Map<String, dynamic>>;
    final languages = data['languages'] as List<Map<String, dynamic>>;
    final name = data['name'] as String;
    final contactLine = [
      _candidateEmail,
      if ((data['phone'] ?? '').toString().isNotEmpty) data['phone'],
      if ((data['city'] ?? '').toString().isNotEmpty) data['city'],
    ].join('  |  ');

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(t,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        );

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: name),
          pw.Text(contactLine, style: const pw.TextStyle(fontSize: 10)),
          if ((data['professional_summary'] ?? '').toString().isNotEmpty) ...[
            sectionTitle("PROFESSIONAL SUMMARY"),
            pw.Text(data['professional_summary']),
          ],
          if (skills.isNotEmpty) ...[
            sectionTitle("SKILLS"),
            ...skills.map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${s['skill_name']} - ${s['category'] ?? ''}"),
                      pw.Text(s['proficiency']),
                    ],
                  ),
                )),
          ],
          if (employment.isNotEmpty) ...[
            sectionTitle("EMPLOYMENT"),
            ...employment.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("${e['designation']} - ${e['company_name']}",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            "${e['start_date'] ?? ''} - ${e['is_current'] == true ? 'Present' : (e['end_date'] ?? '')}",
                            style: const pw.TextStyle(fontSize: 10)),
                        if ((e['description'] ?? '').toString().isNotEmpty)
                          pw.Text(e['description']),
                      ]),
                )),
          ],
          if (projects.isNotEmpty) ...[
            sectionTitle("PROJECTS"),
            ...projects.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(p['title'],
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(p['description']),
                        pw.Text(p['tech_tags'],
                            style: const pw.TextStyle(fontSize: 10)),
                      ]),
                )),
          ],
          if (education.isNotEmpty) ...[
            sectionTitle("EDUCATION"),
            ...education.map((ed) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(ed['degree'],
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            "${ed['institution'] ?? ''} - ${ed['year_of_passing'] ?? ''}",
                            style: const pw.TextStyle(fontSize: 10)),
                      ]),
                )),
          ],
          if (accomplishments.isNotEmpty) ...[
            sectionTitle("ACCOMPLISHMENTS"),
            ...accomplishments.map((a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                      "${a['title']} (${a['type']}, ${a['date_achieved'] ?? ''})"),
                )),
          ],
          if (languages.isNotEmpty) ...[
            sectionTitle("LANGUAGES"),
            pw.Text(languages
                .map((l) => "${l['language_name']} (${l['proficiency']})")
                .join(', ')),
          ],
        ],
      ),
    );
    final bytes = await doc.save();
    if (mounted) {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              name: '${name.replaceAll(' ', '_')}_ATS_Resume.pdf',
              mimeType: 'application/pdf')
        ],
        text: "My ATS Resume",
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            return Center(
              child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
            );
          }
          final data = snapshot.data!;
          final skills = data['skills'] as List<Map<String, dynamic>>;
          final projects = data['projects'] as List<Map<String, dynamic>>;
          final employment = data['employment'] as List<Map<String, dynamic>>;
          final education = data['education'] as List<Map<String, dynamic>>;
          final accomplishments = data['accomplishments'] as List<Map<String, dynamic>>;
          final languages = data['languages'] as List<Map<String, dynamic>>;
          final name = data['name'] as String;
          final resumePath = data['resume_path'] as String?;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              // --- HERO HEADER ---
              ProfileHeroHeader(
                name: name,
                identityStatus: (data['identity_status'] ?? '').toString(),
                pendingVerificationSessionId: _pendingVerificationSessionId,
                skillsCount: skills.length,
                projectsCount: projects.length,
                onVerifyTap: data['identity_status'] == 'verified'
                    ? null
                    : (_pendingVerificationSessionId != null
                        ? _checkVerificationStatus
                        : _startIdentityVerification),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- BASIC DETAILS ---
              ProfileSectionHeaderRow(
                title: "BASIC DETAILS",
                icon: Icons.person_outline,
                onAdd: () => _editBasicDetails(data),
                label: "Edit",
              ),
              SizedBox(height: AppSpacing.sm),
              ProfileInfoCard(
                icon: Icons.person_outline,
                color: AppColors.info,
                title: name,
                subtitle: [
                  if ((data['work_status'] ?? '').toString().isNotEmpty) data['work_status'],
                  if ((data['city'] ?? '').toString().isNotEmpty) data['city'],
                  if ((data['phone'] ?? '').toString().isNotEmpty) data['phone'],
                  _candidateEmail,
                ].join(' · '),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- PROFESSIONAL SUMMARY ---
              ProfileSectionHeaderRow(
                title: "PROFESSIONAL SUMMARY",
                icon: Icons.history_edu,
                onAdd: () => _editSummary(data),
                label: "Edit",
              ),
              SizedBox(height: AppSpacing.sm),
              ProfileInfoCard(
                icon: Icons.history_edu,
                color: AppColors.warning,
                title: (data['professional_summary'] ?? '').toString().isNotEmpty
                    ? "Your Summary"
                    : "No summary yet",
                subtitle: (data['professional_summary'] ?? '').toString().isNotEmpty
                    ? data['professional_summary']
                    : "Tap Edit to add a professional summary",
              ),
              SizedBox(height: AppSpacing.xl),

              // --- SKILLS ---
              ProfileSectionHeaderRow(
                title: "SKILLS",
                icon: Icons.bolt,
                onAdd: _addSkillDialog,
                label: "Add Skill",
              ),
              SizedBox(height: AppSpacing.sm),
              if (skills.isEmpty)
                const ProfileEmptyCard(message: "No skills added yet.")
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
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_proficiencyIcon(s['proficiency']), color: color, size: 18),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['skill_name'], style: AppTypography.bodyMediumBold),
                              if ((s['category'] ?? '').toString().isNotEmpty)
                                Text(
                                  s['category'],
                                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: AppDecorations.pill(color),
                          child: Text(
                            s['proficiency'].toString().toUpperCase(),
                            style: AppTypography.captionBold.copyWith(color: color),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                          onPressed: () => _editSkillDialog(s),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: AppSpacing.xl),

              // --- EMPLOYMENT ---
              ProfileSectionHeaderRow(
                title: "EMPLOYMENT",
                icon: Icons.business_center_outlined,
                onAdd: _addEmploymentDialog,
                label: "Add",
              ),
              SizedBox(height: AppSpacing.sm),
              if (employment.isEmpty)
                const ProfileEmptyCard(message: "No employment history added yet.")
              else
                ...employment.map((e) => ProfileInfoCard(
                      icon: Icons.business_center_outlined,
                      color: Colors.indigo,
                      title: "${e['designation']} @ ${e['company_name']}",
                      subtitle:
                          "${e['start_date'] ?? ''} - ${e['is_current'] == true ? 'Present' : (e['end_date'] ?? '')}",
                      onEdit: () => _editEmploymentDialog(e),
                      onDelete: () => _deleteEmployment(e['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- FEATURED PROJECTS ---
              ProfileSectionHeaderRow(
                title: "FEATURED PROJECTS",
                icon: Icons.rocket_launch_outlined,
                onAdd: _addProjectDialog,
                label: "Add Project",
              ),
              SizedBox(height: AppSpacing.sm),
              if (projects.isEmpty)
                const ProfileEmptyCard(message: "No projects added yet.")
              else
                ...projects.map((p) => ProfileProjectCard(
                      project: p,
                      onEdit: () => _editProjectDialog(p),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- EDUCATION ---
              ProfileSectionHeaderRow(
                title: "EDUCATION",
                icon: Icons.school_outlined,
                onAdd: _addEducationDialog,
                label: "Add",
              ),
              SizedBox(height: AppSpacing.sm),
              if (education.isEmpty)
                const ProfileEmptyCard(message: "No education added yet.")
              else
                ...education.map((ed) => ProfileInfoCard(
                      icon: Icons.school_outlined,
                      color: Colors.brown,
                      title: ed['degree'],
                      subtitle: "${ed['institution'] ?? ''} · ${ed['year_of_passing'] ?? ''}",
                      onEdit: () => _editEducationDialog(ed),
                      onDelete: () => _deleteEducation(ed['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- ACCOMPLISHMENTS ---
              ProfileSectionHeaderRow(
                title: "ACCOMPLISHMENTS",
                icon: Icons.emoji_events_outlined,
                onAdd: _addAccomplishmentDialog,
                label: "Add",
              ),
              SizedBox(height: AppSpacing.sm),
              if (accomplishments.isEmpty)
                const ProfileEmptyCard(message: "No accomplishments added yet.")
              else
                ...accomplishments.map((a) => ProfileInfoCard(
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amber.shade800,
                      title: a['title'],
                      subtitle: "${a['type'] ?? ''} · ${a['date_achieved'] ?? ''}",
                      onEdit: () => _editAccomplishmentDialog(a),
                      onDelete: () => _deleteAccomplishment(a['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- LANGUAGES ---
              ProfileSectionHeaderRow(
                title: "LANGUAGES",
                icon: Icons.translate,
                onAdd: _addLanguageDialog,
                label: "Add",
              ),
              SizedBox(height: AppSpacing.sm),
              if (languages.isEmpty)
                const ProfileEmptyCard(message: "No languages added yet.")
              else
                ...languages.map((l) => ProfileInfoCard(
                      icon: Icons.translate,
                      color: Colors.cyan.shade700,
                      title: l['language_name'],
                      subtitle: l['proficiency'] ?? '',
                      onDelete: () => _deleteLanguage(l['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- CAREER PREFERENCES ---
              ProfileSectionHeaderRow(
                title: "CAREER PREFERENCES",
                icon: Icons.star_border,
                onAdd: () => _editCareerPreferences(data),
                label: "Edit",
              ),
              SizedBox(height: AppSpacing.sm),
              ProfileInfoCard(
                icon: Icons.star_border,
                color: AppColors.info,
                title: (data['preferred_work_mode'] ?? '').toString().isNotEmpty
                    ? data['preferred_work_mode']
                    : "No preference set",
                subtitle: [
                  if ((data['preferred_location'] ?? '').toString().isNotEmpty) data['preferred_location'],
                  if ((data['expected_salary'] ?? '').toString().isNotEmpty) data['expected_salary'],
                ].join(' · '),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- RESUME ---
              Text("RESUME", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
              SizedBox(height: AppSpacing.sm),
              ProfileResumeCard(
                isUploading: _isUploadingResume,
                resumePath: resumePath,
                onTap: _pickAndUploadResume,
              ),
              SizedBox(height: AppSpacing.xl),

              // --- EXPORT ---
              ProfileExportPdfButton(onExport: () => _exportPdf(data)),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
