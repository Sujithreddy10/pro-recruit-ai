import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  String _taskType = 'jd';
  final TextEditingController _extraNotesCtrl = TextEditingController();
  Map<String, dynamic>? _selectedJob;
  Map<String, dynamic>? _selectedApplication;
  bool _isGenerating = false;
  String? _draftText;

  late Future<List<Map<String, dynamic>>> _jobsFuture;
  late Future<List<Map<String, dynamic>>> _applicationsFuture;

  final Map<String, String> _taskLabels = {
    'jd': 'Job Description',
    'outreach': 'Candidate Outreach',
    'rejection': 'Rejection Message',
    'offer': 'Offer Congratulations',
  };

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
    _applicationsFuture = _fetchApplications();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    final data = await Supabase.instance.client.from('jobs').select('id, title, company').order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchApplications() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, status, profiles(full_name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _generateDraft() async {
    String prompt;

    if (_taskType == 'jd') {
      if (_selectedJob == null) return;
      prompt = "Write a professional, concise job description for the role '${_selectedJob!['title']}' at "
          "${_selectedJob!['company']}. Extra requirements/notes: ${_extraNotesCtrl.text.isEmpty ? 'none' : _extraNotesCtrl.text}. "
          "Keep it under 200 words, no markdown formatting.";
    } else {
      if (_selectedApplication == null) return;
      final name = _selectedApplication!['profiles']?['full_name'] ?? 'the candidate';
      final role = _selectedApplication!['job_title'] ?? 'the role';
      final company = _selectedApplication!['company_name'] ?? 'our company';

      switch (_taskType) {
        case 'outreach':
          prompt = "Write a warm, professional outreach message to $name about their application for "
              "$role at $company. Extra notes: ${_extraNotesCtrl.text.isEmpty ? 'none' : _extraNotesCtrl.text}. "
              "Keep it under 120 words, no markdown formatting.";
          break;
        case 'rejection':
          prompt = "Write a polite, respectful rejection message to $name regarding their application for "
              "$role at $company. Be kind but clear, keep the door open for future roles. "
              "Extra notes: ${_extraNotesCtrl.text.isEmpty ? 'none' : _extraNotesCtrl.text}. "
              "Keep it under 100 words, no markdown formatting.";
          break;
        case 'offer':
          prompt = "Write a warm congratulations message to $name, informing them they've been hired for "
              "$role at $company. Extra notes: ${_extraNotesCtrl.text.isEmpty ? 'none' : _extraNotesCtrl.text}. "
              "Keep it under 100 words, no markdown formatting.";
          break;
        default:
          return;
      }
    }

    setState(() {
      _isGenerating = true;
      _draftText = null;
    });

    try {
      // Calls the Supabase Edge Function 'generate-draft', which holds the
      // Gemini API key server-side. The key never ships inside the app.
      final response = await Supabase.instance.client.functions.invoke(
        'generate-draft',
        body: {'prompt': prompt},
      );

      if (response.status != 200) {
        throw 'Server error (${response.status})';
      }

      final data = response.data as Map<String, dynamic>;
      setState(() => _draftText = data['text'] as String? ?? "No response generated.");
    } catch (e) {
      setState(() => _draftText = "Error generating draft: $e");
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _copyDraft() {
    if (_draftText == null) return;
    Clipboard.setData(ClipboardData(text: _draftText!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsJob = _taskType == 'jd';
    final needsCandidate = !needsJob;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("AI Assistant", style: AppTypography.titleMedium.copyWith(color: Colors.deepPurple)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          Text("WHAT DO YOU WANT TO DRAFT?", style: AppTypography.sectionHeader),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: _taskLabels.entries.map((e) {
              final selected = _taskType == e.key;
              return ChoiceChip(
                label: Text(e.value, style: AppTypography.bodySmall.copyWith(color: selected ? AppColors.textLight : AppColors.textDark)),
                selected: selected,
                selectedColor: Colors.deepPurple,
                onSelected: (_) => setState(() {
                  _taskType = e.key;
                  _selectedJob = null;
                  _selectedApplication = null;
                  _draftText = null;
                }),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.xl),
          if (needsJob) ...[
            Text("SELECT JOB", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) return Text("No jobs found.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted));
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
                  initialValue: _selectedJob,
                  isExpanded: true,
                  items: jobs
                      .map((j) => DropdownMenuItem<Map<String, dynamic>>(
                            value: j,
                            child: Text(
                              "${j['title']} @ ${j['company']}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTypography.bodyMedium,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedJob = v),
                );
              },
            ),
          ],
          if (needsCandidate) ...[
            Text("SELECT CANDIDATE APPLICATION", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                final apps = snapshot.data ?? [];
                if (apps.isEmpty) return Text("No applications found.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted));
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
                  initialValue: _selectedApplication,
                  items: apps.map((a) {
                    final name = a['profiles']?['full_name'] ?? 'Unknown';
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: a,
                      child: Text(
                        "$name — ${a['job_title']}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedApplication = v),
                );
              },
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          Text("EXTRA NOTES (OPTIONAL)", style: AppTypography.sectionHeader),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _extraNotesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Any specific points to include...",
              border: OutlineInputBorder(borderRadius: AppBorderRadius.small),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateDraft,
            icon: _isGenerating
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLight))
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_isGenerating ? "Generating..." : "Generate Draft", style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textLight)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: AppColors.textLight,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
            ),
          ),
          if (_draftText != null) ...[
            SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("DRAFT", style: AppTypography.sectionHeader),
                TextButton.icon(
                  onPressed: _copyDraft,
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text("Copy", style: AppTypography.bodySmall),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.05),
                borderRadius: AppBorderRadius.medium,
                border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.15)),
              ),
              child: TextFormField(
                maxLines: null,
                onChanged: (v) => _draftText = v,
                style: AppTypography.bodyMedium.copyWith(height: 1.5),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
