import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final workStatusCtrl =
        TextEditingController(text: data['work_status'] ?? '');
    final cityCtrl = TextEditingController(text: data['city'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final availabilityCtrl =
        TextEditingController(text: data['availability'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Edit Basic Details", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              enabled: false,
              controller: TextEditingController(text: _candidateEmail),
              decoration:
                  const InputDecoration(labelText: "Email ID (login email)"),
            ),
            TextField(
                controller: workStatusCtrl,
                decoration: const InputDecoration(labelText: "Work Status")),
            TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: "Current City")),
            TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: "Mobile Number")),
            TextField(
                controller: availabilityCtrl,
                decoration:
                    const InputDecoration(labelText: "Availability to Join")),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (result == true) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('profiles').update({
          'work_status': workStatusCtrl.text.trim(),
          'city': cityCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'availability': availabilityCtrl.text.trim(),
        }).eq('id', userId);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to save: $e")));
        }
      }
    }
  }

  // ---------- PROFESSIONAL SUMMARY ----------
  Future<void> _editSummary(Map<String, dynamic> data) async {
    final summaryCtrl =
        TextEditingController(text: data['professional_summary'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title:
            Text("Edit Professional Summary", style: AppTypography.titleMedium),
        content: TextField(
          controller: summaryCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
              labelText: "Professional Summary",
              hintText: "2-3 sentences about your experience and strengths"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (result == true) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('profiles').update({
          'professional_summary': summaryCtrl.text.trim(),
        }).eq('id', userId);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to save: $e")));
        }
      }
    }
  }

  // ---------- CAREER PREFERENCES ----------
  Future<void> _editCareerPreferences(Map<String, dynamic> data) async {
    final modes = {'Remote', 'Hybrid', 'On-site'};
    final selectedModes = (data['preferred_work_mode'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final locations = (data['preferred_location'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final salaryCtrl =
        TextEditingController(text: data['expected_salary'] ?? '');
    final locationCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title:
              Text("Edit Career Preferences", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Work Mode", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: modes.map((m) {
                    final selected = selectedModes.contains(m);
                    return FilterChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (v) => setDialogState(() {
                        if (v) {
                          selectedModes.add(m);
                        } else {
                          selectedModes.remove(m);
                        }
                      }),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.md),
                Text("Preferred Locations", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: locationCtrl,
                      decoration:
                          const InputDecoration(labelText: "Add a city"),
                      onSubmitted: (v) {
                        final city = v.trim();
                        if (city.isNotEmpty && !locations.contains(city)) {
                          setDialogState(() {
                            locations.add(city);
                            locationCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final city = locationCtrl.text.trim();
                      if (city.isNotEmpty && !locations.contains(city)) {
                        setDialogState(() {
                          locations.add(city);
                          locationCtrl.clear();
                        });
                      }
                    },
                  ),
                ]),
                SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: locations
                      .map((city) => Chip(
                            label: Text(city),
                            onDeleted: () =>
                                setDialogState(() => locations.remove(city)),
                          ))
                      .toList(),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                    controller: salaryCtrl,
                    decoration: const InputDecoration(
                        labelText: "Expected Salary (e.g. 30LPA+)")),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Save")),
          ],
        ),
      ),
    );
    if (result == true) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('profiles').update({
          'preferred_work_mode': selectedModes.join(', '),
          'preferred_location': locations.join(', '),
          'expected_salary': salaryCtrl.text.trim(),
        }).eq('id', userId);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to save: $e")));
        }
      }
    }
  }

  // ---------- SKILLS ----------
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
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: "Skill Name (e.g. FastAPI)")),
              TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                      labelText: "Category (e.g. REST API Development)")),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: proficiency,
                decoration: const InputDecoration(labelText: "Proficiency"),
                items: ['Beginner', 'Pro', 'Advanced']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => proficiency = v ?? 'Beginner'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Add")),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to add skill: $e")));
        }
      }
    }
  }

  Future<void> _editSkillDialog(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['skill_name'] ?? '');
    final categoryCtrl = TextEditingController(text: item['category'] ?? '');
    String proficiency = (item['proficiency'] as String?) ?? 'Beginner';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Edit Skill", style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: "Skill Name (e.g. FastAPI)")),
              TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                      labelText: "Category (e.g. REST API Development)")),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: proficiency,
                decoration: const InputDecoration(labelText: "Proficiency"),
                items: ['Beginner', 'Pro', 'Advanced']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => proficiency = v ?? 'Beginner'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Save")),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('candidate_skills').update({
          'skill_name': nameCtrl.text.trim(),
          'category': categoryCtrl.text.trim(),
          'proficiency': proficiency,
        }).eq('id', item['id']);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to update: $e")));
        }
      }
    }
  }

  // ---------- PROJECTS ----------
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
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: "Project Title")),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description")),
              TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                      labelText: "Tech Tags (comma separated)")),
              TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                      labelText: "Project Link (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Add")),
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
          'project_link':
              linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add project: $e")));
        }
      }
    }
  }

  Future<void> _editProjectDialog(Map<String, dynamic> item) async {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    final tagsCtrl = TextEditingController(text: item['tech_tags'] ?? '');
    final linkCtrl = TextEditingController(text: item['project_link'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Edit Project", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: "Project Title")),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description")),
              TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                      labelText: "Tech Tags (comma separated)")),
              TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                      labelText: "Project Link (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('candidate_projects').update({
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'tech_tags': tagsCtrl.text.trim(),
          'project_link':
              linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
        }).eq('id', item['id']);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to update: $e")));
        }
      }
    }
  }

  // ---------- EMPLOYMENT ----------
  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Widget _datePickerField(BuildContext ctx, String label, DateTime? value,
      bool enabled, void Function(DateTime) onPicked) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1980),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) onPicked(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon:
                  Icon(Icons.calendar_today, color: Colors.indigo, size: 18),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.small,
                  borderSide: BorderSide.none),
            ),
            child: Text(value == null ? "Select date" : _fmtDate(value)),
          ),
        ),
      ),
    );
  }

  Future<void> _addEmploymentDialog() async {
    final companyCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isCurrent = false;
    DateTime? startDate;
    DateTime? endDate;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Add Employment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: "Company Name")),
              TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(labelText: "Designation")),
              SizedBox(height: AppSpacing.md),
              _datePickerField(ctx, "Start Date", startDate, true,
                  (d) => setDialogState(() => startDate = d)),
              SizedBox(height: AppSpacing.md),
              _datePickerField(ctx, "End Date", endDate, !isCurrent,
                  (d) => setDialogState(() => endDate = d)),
              CheckboxListTile(
                value: isCurrent,
                title: const Text("I currently work here"),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
              ),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description")),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Add")),
          ],
        ),
      ),
    );
    if (result == true && companyCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('candidate_employment').insert({
          'user_id': userId,
          'company_name': companyCtrl.text.trim(),
          'designation': designationCtrl.text.trim(),
          'start_date': startDate != null ? _fmtDate(startDate!) : null,
          'end_date':
              isCurrent ? null : (endDate != null ? _fmtDate(endDate!) : null),
          'is_current': isCurrent,
          'description': descCtrl.text.trim(),
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to add: $e")));
        }
      }
    }
  }

  Future<void> _deleteEmployment(String id) async {
    try {
      await Supabase.instance.client
          .from('candidate_employment')
          .delete()
          .eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
      }
    }
  }

  Future<void> _editEmploymentDialog(Map<String, dynamic> item) async {
    final companyCtrl = TextEditingController(text: item['company_name'] ?? '');
    final designationCtrl =
        TextEditingController(text: item['designation'] ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    bool isCurrent = item['is_current'] == true;
    DateTime? startDate = item['start_date'] != null
        ? DateTime.tryParse(item['start_date'])
        : null;
    DateTime? endDate =
        item['end_date'] != null ? DateTime.tryParse(item['end_date']) : null;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Edit Employment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: "Company Name")),
              TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(labelText: "Designation")),
              SizedBox(height: AppSpacing.md),
              _datePickerField(ctx, "Start Date", startDate, true,
                  (d) => setDialogState(() => startDate = d)),
              SizedBox(height: AppSpacing.md),
              _datePickerField(ctx, "End Date", endDate, !isCurrent,
                  (d) => setDialogState(() => endDate = d)),
              CheckboxListTile(
                value: isCurrent,
                title: const Text("I currently work here"),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
              ),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description")),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Save")),
          ],
        ),
      ),
    );
    if (result == true && companyCtrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('candidate_employment').update({
          'company_name': companyCtrl.text.trim(),
          'designation': designationCtrl.text.trim(),
          'start_date': startDate != null
              ? DateTime(startDate!.year, startDate!.month, startDate!.day)
                  .toIso8601String()
              : null,
          'end_date': isCurrent
              ? null
              : (endDate != null
                  ? DateTime(endDate!.year, endDate!.month, endDate!.day)
                      .toIso8601String()
                  : null),
          'is_current': isCurrent,
          'description': descCtrl.text.trim(),
        }).eq('id', item['id']);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to update: $e")));
        }
      }
    }
  }

  // ---------- EDUCATION ----------
  Future<void> _addEducationDialog() async {
    final degreeCtrl = TextEditingController();
    final institutionCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Add Education", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: degreeCtrl,
                decoration: const InputDecoration(
                    labelText: "Degree (e.g. B.Tech Computer Science)")),
            TextField(
                controller: institutionCtrl,
                decoration: const InputDecoration(labelText: "Institution")),
            TextField(
                controller: yearCtrl,
                decoration:
                    const InputDecoration(labelText: "Year of Passing")),
            TextField(
                controller: gradeCtrl,
                decoration: const InputDecoration(
                    labelText: "Grade / CGPA (optional)")),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Add")),
        ],
      ),
    );
    if (result == true && degreeCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('candidate_education').insert({
          'user_id': userId,
          'degree': degreeCtrl.text.trim(),
          'institution': institutionCtrl.text.trim(),
          'year_of_passing': yearCtrl.text.trim(),
          'grade': gradeCtrl.text.trim(),
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to add: $e")));
        }
      }
    }
  }

  Future<void> _deleteEducation(String id) async {
    try {
      await Supabase.instance.client
          .from('candidate_education')
          .delete()
          .eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
      }
    }
  }

  Future<void> _editEducationDialog(Map<String, dynamic> item) async {
    final degreeCtrl = TextEditingController(text: item['degree'] ?? '');
    final institutionCtrl =
        TextEditingController(text: item['institution'] ?? '');
    final yearCtrl =
        TextEditingController(text: item['year_of_passing']?.toString() ?? '');
    final gradeCtrl = TextEditingController(text: item['grade'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Edit Education", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: degreeCtrl,
                decoration: const InputDecoration(
                    labelText: "Degree (e.g. B.Tech Computer Science)")),
            TextField(
                controller: institutionCtrl,
                decoration: const InputDecoration(labelText: "Institution")),
            TextField(
                controller: yearCtrl,
                decoration:
                    const InputDecoration(labelText: "Year of Passing")),
            TextField(
                controller: gradeCtrl,
                decoration: const InputDecoration(
                    labelText: "Grade / CGPA (optional)")),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (result == true && degreeCtrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('candidate_education').update({
          'degree': degreeCtrl.text.trim(),
          'institution': institutionCtrl.text.trim(),
          'year_of_passing': yearCtrl.text.trim(),
          'grade': gradeCtrl.text.trim(),
        }).eq('id', item['id']);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to update: $e")));
        }
      }
    }
  }

  // ---------- ACCOMPLISHMENTS ----------
  Future<void> _addAccomplishmentDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    String type = 'Award';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Add Accomplishment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Title")),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: "Type"),
                items: ['Award', 'Certification', 'Achievement']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v ?? 'Award'),
              ),
              TextField(
                  controller: dateCtrl,
                  decoration:
                      const InputDecoration(labelText: "Date (e.g. Mar 2024)")),
              TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: "Description (optional)")),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Add")),
          ],
        ),
      ),
    );
    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client
            .from('candidate_accomplishments')
            .insert({
          'user_id': userId,
          'title': titleCtrl.text.trim(),
          'type': type,
          'description': descCtrl.text.trim(),
          'date_achieved': dateCtrl.text.trim(),
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to add: $e")));
        }
      }
    }
  }

  Future<void> _deleteAccomplishment(String id) async {
    try {
      await Supabase.instance.client
          .from('candidate_accomplishments')
          .delete()
          .eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
      }
    }
  }

  Future<void> _editAccomplishmentDialog(Map<String, dynamic> item) async {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final descCtrl = TextEditingController(text: item['description'] ?? '');
    final dateCtrl = TextEditingController(text: item['date_achieved'] ?? '');
    String type = (item['type'] as String?) ?? 'Award';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Edit Accomplishment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Title")),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: "Type"),
                items: ['Award', 'Certification', 'Achievement']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v ?? 'Award'),
              ),
              TextField(
                  controller: dateCtrl,
                  decoration:
                      const InputDecoration(labelText: "Date (e.g. Mar 2024)")),
              TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: "Description (optional)")),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Save")),
          ],
        ),
      ),
    );
    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('candidate_accomplishments')
            .update({
          'title': titleCtrl.text.trim(),
          'type': type,
          'description': descCtrl.text.trim(),
          'date_achieved': dateCtrl.text.trim(),
        }).eq('id', item['id']);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to update: $e")));
        }
      }
    }
  }

  // ---------- LANGUAGES ----------
  Future<void> _addLanguageDialog() async {
    final nameCtrl = TextEditingController();
    String proficiency = 'Beginner';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Add Language", style: AppTypography.titleMedium),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Language (e.g. English)")),
            SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: proficiency,
              decoration: const InputDecoration(labelText: "Proficiency"),
              items: ['Beginner', 'Advanced', 'Pro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setDialogState(() => proficiency = v ?? 'Beginner'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Add")),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      try {
        await Supabase.instance.client.from('candidate_languages').insert({
          'user_id': userId,
          'language_name': nameCtrl.text.trim(),
          'proficiency': proficiency,
        });
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to add: $e")));
        }
      }
    }
  }

  Future<void> _deleteLanguage(String id) async {
    try {
      await Supabase.instance.client
          .from('candidate_languages')
          .delete()
          .eq('id', id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
      }
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

  // ---------- SHARED UI HELPERS ----------
  Widget _sectionHeaderRow(String title, IconData icon, VoidCallback onAdd,
          {String label = "Add"}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            SizedBox(width: AppSpacing.xs),
            Text(title,
                style: AppTypography.sectionHeader
                    .copyWith(color: AppColors.primary)),
          ]),
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(
                label == "Edit"
                    ? Icons.edit_outlined
                    : Icons.add_circle_outline,
                size: 16),
            label: Text(label),
          ),
        ],
      );

  Widget _emptyCard(String msg) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Text(msg,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      );

  Widget _infoCard(
          {required IconData icon,
          required Color color,
          required String title,
          required String subtitle,
          VoidCallback? onEdit,
          VoidCallback? onDelete}) =>
      Container(
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
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMediumBold),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textMuted),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textMuted),
                onPressed: onDelete,
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
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
                child: Text("Error: ${snapshot.error}",
                    style: AppTypography.bodyMedium));
          }
          final data = snapshot.data!;
          final skills = data['skills'] as List<Map<String, dynamic>>;
          final projects = data['projects'] as List<Map<String, dynamic>>;
          final employment = data['employment'] as List<Map<String, dynamic>>;
          final education = data['education'] as List<Map<String, dynamic>>;
          final accomplishments =
              data['accomplishments'] as List<Map<String, dynamic>>;
          final languages = data['languages'] as List<Map<String, dynamic>>;
          final name = data['name'] as String;
          final resumePath = data['resume_path'] as String?;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              // --- HERO HEADER ---
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      Colors.indigo.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.headlineLarge
                            .copyWith(color: AppColors.textLight, fontSize: 28),
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: data['identity_status'] == 'verified'
                                ? null
                                : (_pendingVerificationSessionId != null
                                    ? _checkVerificationStatus
                                    : _startIdentityVerification),
                            child: Row(children: [
                              Icon(
                                data['identity_status'] == 'verified'
                                    ? Icons.verified
                                    : (_pendingVerificationSessionId != null
                                        ? Icons.refresh
                                        : Icons.gpp_maybe_outlined),
                                color: data['identity_status'] == 'verified'
                                    ? Colors.greenAccent
                                    : Colors.white60,
                                size: 16,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                data['identity_status'] == 'verified'
                                    ? "HYLO VERIFIED"
                                    : (_pendingVerificationSessionId != null
                                        ? "CHECK STATUS"
                                        : "VERIFY IDENTITY"),
                                style: AppTypography.sectionHeader.copyWith(
                                  color: data['identity_status'] == 'verified'
                                      ? Colors.greenAccent
                                      : Colors.white60,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ]),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(name,
                              style: AppTypography.headlineLarge.copyWith(
                                  color: AppColors.textLight, fontSize: 20)),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                              "${skills.length} skills · ${projects.length} projects",
                              style: AppTypography.caption
                                  .copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- BASIC DETAILS ---
              _sectionHeaderRow("BASIC DETAILS", Icons.person_outline,
                  () => _editBasicDetails(data),
                  label: "Edit"),
              SizedBox(height: AppSpacing.sm),
              _infoCard(
                icon: Icons.person_outline,
                color: AppColors.info,
                title: name,
                subtitle: [
                  if ((data['work_status'] ?? '').toString().isNotEmpty)
                    data['work_status'],
                  if ((data['city'] ?? '').toString().isNotEmpty) data['city'],
                  if ((data['phone'] ?? '').toString().isNotEmpty)
                    data['phone'],
                  _candidateEmail,
                ].join(' · '),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- PROFESSIONAL SUMMARY ---
              _sectionHeaderRow("PROFESSIONAL SUMMARY", Icons.history_edu,
                  () => _editSummary(data),
                  label: "Edit"),
              SizedBox(height: AppSpacing.sm),
              _infoCard(
                icon: Icons.history_edu,
                color: AppColors.warning,
                title:
                    (data['professional_summary'] ?? '').toString().isNotEmpty
                        ? "Your Summary"
                        : "No summary yet",
                subtitle:
                    (data['professional_summary'] ?? '').toString().isNotEmpty
                        ? data['professional_summary']
                        : "Tap Edit to add a professional summary",
              ),
              SizedBox(height: AppSpacing.xl),

              // --- SKILLS ---
              _sectionHeaderRow("SKILLS", Icons.bolt, _addSkillDialog,
                  label: "Add Skill"),
              SizedBox(height: AppSpacing.sm),
              if (skills.isEmpty)
                _emptyCard("No skills added yet.")
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
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                          child: Icon(_proficiencyIcon(s['proficiency']),
                              color: color, size: 18),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['skill_name'],
                                  style: AppTypography.bodyMediumBold),
                              if ((s['category'] ?? '').toString().isNotEmpty)
                                Text(s['category'],
                                    style: AppTypography.caption
                                        .copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs),
                          decoration: AppDecorations.pill(color),
                          child: Text(s['proficiency'].toString().toUpperCase(),
                              style: AppTypography.captionBold
                                  .copyWith(color: color)),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.textMuted),
                          onPressed: () => _editSkillDialog(s),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: AppSpacing.xl),

              // --- EMPLOYMENT ---
              _sectionHeaderRow("EMPLOYMENT", Icons.business_center_outlined,
                  _addEmploymentDialog,
                  label: "Add"),
              SizedBox(height: AppSpacing.sm),
              if (employment.isEmpty)
                _emptyCard("No employment history added yet.")
              else
                ...employment.map((e) => _infoCard(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.rocket_launch_outlined,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text("FEATURED PROJECTS",
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.primary)),
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
                _emptyCard("No projects added yet.")
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
                        colors: [
                          Colors.indigo.shade50,
                          AppColors.primary.withValues(alpha: 0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.folder_special_outlined,
                              size: 18, color: AppColors.primary),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(p['title'],
                                style: AppTypography.bodyMediumBold
                                    .copyWith(color: AppColors.primary)),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.primary),
                            onPressed: () => _editProjectDialog(p),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(t,
                                        style: AppTypography.captionBold
                                            .copyWith(
                                                color: AppColors.primary)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: AppSpacing.xl),

              // --- EDUCATION ---
              _sectionHeaderRow(
                  "EDUCATION", Icons.school_outlined, _addEducationDialog,
                  label: "Add"),
              SizedBox(height: AppSpacing.sm),
              if (education.isEmpty)
                _emptyCard("No education added yet.")
              else
                ...education.map((ed) => _infoCard(
                      icon: Icons.school_outlined,
                      color: Colors.brown,
                      title: ed['degree'],
                      subtitle:
                          "${ed['institution'] ?? ''} · ${ed['year_of_passing'] ?? ''}",
                      onEdit: () => _editEducationDialog(ed),
                      onDelete: () => _deleteEducation(ed['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- ACCOMPLISHMENTS ---
              _sectionHeaderRow("ACCOMPLISHMENTS", Icons.emoji_events_outlined,
                  _addAccomplishmentDialog,
                  label: "Add"),
              SizedBox(height: AppSpacing.sm),
              if (accomplishments.isEmpty)
                _emptyCard("No accomplishments added yet.")
              else
                ...accomplishments.map((a) => _infoCard(
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amber.shade800,
                      title: a['title'],
                      subtitle:
                          "${a['type'] ?? ''} · ${a['date_achieved'] ?? ''}",
                      onEdit: () => _editAccomplishmentDialog(a),
                      onDelete: () => _deleteAccomplishment(a['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- LANGUAGES ---
              _sectionHeaderRow(
                  "LANGUAGES", Icons.translate, _addLanguageDialog,
                  label: "Add"),
              SizedBox(height: AppSpacing.sm),
              if (languages.isEmpty)
                _emptyCard("No languages added yet.")
              else
                ...languages.map((l) => _infoCard(
                      icon: Icons.translate,
                      color: Colors.cyan.shade700,
                      title: l['language_name'],
                      subtitle: l['proficiency'] ?? '',
                      onDelete: () => _deleteLanguage(l['id']),
                    )),
              SizedBox(height: AppSpacing.xl),

              // --- CAREER PREFERENCES ---
              _sectionHeaderRow("CAREER PREFERENCES", Icons.star_border,
                  () => _editCareerPreferences(data),
                  label: "Edit"),
              SizedBox(height: AppSpacing.sm),
              _infoCard(
                icon: Icons.star_border,
                color: AppColors.info,
                title: (data['preferred_work_mode'] ?? '').toString().isNotEmpty
                    ? data['preferred_work_mode']
                    : "No preference set",
                subtitle: [
                  if ((data['preferred_location'] ?? '').toString().isNotEmpty)
                    data['preferred_location'],
                  if ((data['expected_salary'] ?? '').toString().isNotEmpty)
                    data['expected_salary'],
                ].join(' · '),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- RESUME ---
              Text("RESUME",
                  style: AppTypography.sectionHeader
                      .copyWith(color: AppColors.primary)),
              SizedBox(height: AppSpacing.sm),
              Card(
                elevation: 0.2,
                shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.medium),
                child: ListTile(
                  onTap: _isUploadingResume ? null : _pickAndUploadResume,
                  leading: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: AppBorderRadius.small),
                    child: Icon(Icons.description_outlined,
                        color: AppColors.success, size: 20),
                  ),
                  title: const Text("Resume"),
                  subtitle: Text(_isUploadingResume
                      ? "Uploading..."
                      : (resumePath != null
                          ? resumePath.split('/').last
                          : "No resume uploaded yet")),
                  trailing: const Icon(Icons.upload_file, size: 20),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- EXPORT ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary]),
                  borderRadius: AppBorderRadius.medium,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8))
                  ],
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
