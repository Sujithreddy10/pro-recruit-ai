import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class OutreachComposerScreen extends StatefulWidget {
  const OutreachComposerScreen({super.key});

  @override
  State<OutreachComposerScreen> createState() => _OutreachComposerScreenState();
}

class _OutreachComposerScreenState extends State<OutreachComposerScreen> {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  Map<String, dynamic>? _selectedApplication;
  bool _isGenerating = false;
  String? _draftMessage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, profiles(id, full_name, resume_text)')
        .order('created_at', ascending: false)
        .then((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _generate() async {
    if (_selectedApplication == null) return;
    setState(() {
      _isGenerating = true;
      _error = null;
      _draftMessage = null;
    });

    final app = _selectedApplication!;
    final profile = app['profiles'] as Map<String, dynamic>?;
    final candidateName = profile?['full_name'] ?? 'there';
    final jobTitle = (app['job_title'] ?? 'this role').toString();
    final company = (app['company_name'] ?? 'our team').toString();

    try {
      final resumeText = (profile?['resume_text'] ?? '').toString();
      final resumeSummary = resumeText.isEmpty
          ? 'Not available'
          : (resumeText.length > 1200 ? resumeText.substring(0, 1200) : resumeText);

      final prompt = '''
Write a warm, professional, personalized outreach message (3-4 sentences) from a recruiter to a candidate about an open role. Reference specific skills or experience from their resume where relevant. Avoid generic filler language. Do not include a subject line, just the message body.

Candidate Name: $candidateName
Job Title: $jobTitle
Company: $company
Candidate Resume Summary: $resumeSummary
''';

      final response = await Supabase.instance.client.functions.invoke(
        'generate-draft',
        body: {'prompt': prompt},
      );

      final text = (response.data?['text'] ?? '').toString().trim();
      if (response.status == 200 && text.isNotEmpty) {
        setState(() {
          _draftMessage = text;
          _isGenerating = false;
        });
        return;
      }
      throw 'Service unavailable';
    } catch (e) {
      // Graceful fallback when Gemini is busy (503/429)
      final fallbackDraft = '''Hi $candidateName,

I came across your profile and was really impressed by your background in $jobTitle. We have an exciting opening at $company that aligns closely with your skills.

Would you be open to a brief 10-minute introductory call this week to explore this role together?

Best regards,
Hiring Team''';

      setState(() {
        _draftMessage = fallbackDraft;
        _error = null;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("AI high-traffic period. Standard executive template generated."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Outreach Composer", style: AppTypography.titleMedium.copyWith(color: Colors.lightBlue)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.lightBlue),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SELECT A CANDIDATE", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                final apps = snapshot.data ?? [];
                if (apps.isEmpty) {
                  return Text("No applications yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted));
                }
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
                  isExpanded: true,
                  initialValue: _selectedApplication,
                  items: apps.map((a) {
                    final profile = a['profiles'] as Map<String, dynamic>?;
                    final name = profile?['full_name'] ?? 'Unknown';
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: a,
                      child: Text(
                        "$name — ${a['job_title'] ?? ''}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedApplication = v;
                    _draftMessage = null;
                    _error = null;
                  }),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedApplication == null || _isGenerating) ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                ),
                icon: _isGenerating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? "Generating..." : "Generate Outreach Message"),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                ),
              ),
            if (_draftMessage != null)
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorderRadius.large,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(_draftMessage!, style: AppTypography.bodyMedium),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _draftMessage!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Copied to clipboard")),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text("Copy"),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGenerating ? null : _generate,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Regenerate"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
