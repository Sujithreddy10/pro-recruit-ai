import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class MNCQuestionBankScreen extends StatefulWidget {
  const MNCQuestionBankScreen({super.key});

  @override
  State<MNCQuestionBankScreen> createState() => _MNCQuestionBankScreenState();
}

class _MNCQuestionBankScreenState extends State<MNCQuestionBankScreen> {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  Map<String, dynamic>? _selectedApplication;
  bool _isGenerating = false;
  List<dynamic>? _questions;
  String? _error;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _applicationsFuture = userId == null
        ? Future.value([])
        : Supabase.instance.client
            .from('applications')
            .select('id, job_title, company_name')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .then((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _generate() async {
    if (_selectedApplication == null) return;
    setState(() {
      _isGenerating = true;
      _error = null;
      _questions = null;
    });
    try {
      final app = _selectedApplication!;
      final prompt = '''
You are an expert interview coach. Generate a tailored interview question bank for this specific role and company. Include a mix of technical, behavioral, and company-culture questions. Respond with ONLY valid JSON, no markdown formatting, no code fences, no extra text, in exactly this shape:
{"questions": [{"question": "<question text>", "category": "Technical|Behavioral|Company Culture", "tip": "<one sentence prep tip>"}]}

Generate 8 to 10 questions total, mixing all three categories.

Job Title: ${app['job_title'] ?? ''}
Company: ${app['company_name'] ?? ''}
''';

      final response = await Supabase.instance.client.functions.invoke(
        'generate-draft',
        body: {'prompt': prompt},
      );

      final rawText = (response.data?['text'] ?? '').toString();
      final cleaned = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      if (mounted) setState(() => _questions = (parsed['questions'] as List?) ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't generate questions: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Technical':
        return Colors.indigo;
      case 'Behavioral':
        return Colors.teal;
      case 'Company Culture':
        return Colors.deepOrange;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Interview Question Bank", style: AppTypography.titleMedium.copyWith(color: AppColors.info)),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.info),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SELECT AN APPLICATION", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                final apps = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (apps.isEmpty) {
                  return Text(
                    "Apply to a job first to get tailored interview questions for it.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  );
                }
                return DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: AppBorderRadius.small)),
                  isExpanded: true,
                  initialValue: _selectedApplication,
                  items: apps
                      .map((a) => DropdownMenuItem<Map<String, dynamic>>(
                            value: a,
                            child: Text(
                              "${a['job_title']} @ ${a['company_name']}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTypography.bodyMedium,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedApplication = v;
                    _questions = null;
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
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                ),
                icon: _isGenerating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? "Generating..." : "Generate Question Bank"),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                ),
              ),
            if (_questions != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _questions!.length,
                  itemBuilder: (c, i) {
                    final q = _questions![i] as Map<String, dynamic>;
                    final color = _categoryColor(q['category']);
                    return Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorderRadius.large,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (q['category'] ?? '').toString(),
                                  style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                color: AppColors.textMuted,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: q['question'] ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Question copied")),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(q['question'] ?? '', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                          if ((q['tip'] ?? '').toString().isNotEmpty) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text("Tip: ${q['tip']}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
