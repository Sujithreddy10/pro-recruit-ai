import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class JobPostOptimizerScreen extends StatefulWidget {
  const JobPostOptimizerScreen({super.key});

  @override
  State<JobPostOptimizerScreen> createState() => _JobPostOptimizerScreenState();
}

class _JobPostOptimizerScreenState extends State<JobPostOptimizerScreen> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;
  Map<String, dynamic>? _selectedJob;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jobsFuture = Supabase.instance.client
        .from('jobs')
        .select('id, title, company')
        .order('title')
        .then((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _analyze() async {
    if (_selectedJob == null) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });
    try {
      final job = await Supabase.instance.client
          .from('jobs')
          .select('*')
          .eq('id', _selectedJob!['id'])
          .single();

      final prompt = '''
You are an expert recruiting copywriter. Analyze this job posting for clarity, inclusivity (flag biased or exclusionary language), and completeness (salary transparency, clear requirements). Respond with ONLY valid JSON, no markdown formatting, no code fences, no extra text, in exactly this shape:
{"score": <integer 0-100>, "issues": [{"label": "<short label>", "severity": "low|medium|high", "detail": "<one sentence>"}], "suggestedRewrite": "<an improved version of the full job description>"}

Job Title: ${job['title'] ?? ''}
Company: ${job['company'] ?? ''}
Work Mode: ${job['mode'] ?? 'Not specified'}
Salary Range: ${job['salary_range']?.toString().isNotEmpty == true ? job['salary_range'] : 'Not specified'}
Description: ${job['description'] ?? ''}
''';

      final response = await Supabase.instance.client.functions.invoke(
        'generate-draft',
        body: {'prompt': prompt},
      );

      final rawText = (response.data?['text'] ?? '').toString();
      final cleaned = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      if (mounted) setState(() => _result = parsed);
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't analyze this posting: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return Colors.orange;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Job Post Optimizer", style: AppTypography.titleMedium.copyWith(color: Colors.deepOrangeAccent)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.deepOrangeAccent),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SELECT A JOB POSTING", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return Text("No jobs posted yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted));
                }
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
                  isExpanded: true,
                  value: _selectedJob,
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
                  onChanged: (v) => setState(() {
                    _selectedJob = v;
                    _result = null;
                    _error = null;
                  }),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedJob == null || _isAnalyzing) ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                ),
                icon: _isAnalyzing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isAnalyzing ? "Analyzing..." : "Analyze & Optimize"),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
            if (_result != null)
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFFF59E0B)]),
                        borderRadius: AppBorderRadius.large,
                      ),
                      child: Row(
                        children: [
                          Text("${_result!['score'] ?? 0}", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 40)),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text("Job Post Quality Score", style: AppTypography.bodyMedium.copyWith(color: Colors.white70))),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text("ISSUES FOUND", style: AppTypography.sectionHeader),
                    SizedBox(height: AppSpacing.sm),
                    ...((_result!['issues'] as List?) ?? []).map((issue) => Container(
                          margin: EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppBorderRadius.small,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.flag, size: 18, color: _severityColor(issue['severity'])),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(issue['label'] ?? '', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                                    Text(issue['detail'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    SizedBox(height: AppSpacing.md),
                    Text("SUGGESTED REWRITE", style: AppTypography.sectionHeader),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppBorderRadius.small,
                      ),
                      child: Text(_result!['suggestedRewrite'] ?? '', style: AppTypography.bodySmall),
                    ),
                    SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _result!['suggestedRewrite'] ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied to clipboard")),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy Rewrite"),
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
