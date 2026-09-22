import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_score_widgets.dart';

class ResumeScoreScreen extends StatefulWidget {
  const ResumeScoreScreen({super.key});

  @override
  State<ResumeScoreScreen> createState() => _ResumeScoreScreenState();
}

class _ResumeScoreScreenState extends State<ResumeScoreScreen> {
  late Future<ResumeAnalysisData> _generalFuture;
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _selectedJob;
  Map<String, dynamic>? _jobMatch;
  bool _loadingJobMatch = false;

  @override
  void initState() {
    super.initState();
    _generalFuture = _loadGeneralAnalysis();
  }

  Future<ResumeAnalysisData> _loadGeneralAnalysis() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return ResumeAnalysisData(hasResume: false, score: 0, checks: []);
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('resume_path')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['resume_path'] == null || (profile['resume_path'] as String).isEmpty) {
        return ResumeAnalysisData(hasResume: false, score: 0, checks: []);
      }

      final jobsRes = await Supabase.instance.client.from('jobs').select('id, title, company').limit(10);
      if (mounted) {
        setState(() {
          _jobs = List<Map<String, dynamic>>.from(jobsRes);
          if (_jobs.isNotEmpty) _selectedJob = _jobs.first;
        });
      }

      final response = await Supabase.instance.client.functions.invoke(
        'extract-resume-text',
        body: {'userId': userId, if (_selectedJob != null) 'jobId': _selectedJob!['id']},
      );

      final data = response.data;
      if (data == null) {
        return ResumeAnalysisData(hasResume: true, score: 50, checks: [], errorMessage: "No data returned from AI analyzer");
      }

      if (data['jobMatch'] != null && mounted) {
        setState(() => _jobMatch = Map<String, dynamic>.from(data['jobMatch']));
      }

      final score = (data['score'] as num?)?.toInt() ?? 50;
      final checks = (data['checks'] as List<dynamic>?)?.map((c) => Map<String, dynamic>.from(c as Map)).toList() ?? [];

      return ResumeAnalysisData(hasResume: true, score: score, checks: checks);
    } catch (e) {
      return ResumeAnalysisData(hasResume: true, score: 0, checks: [], errorMessage: e.toString());
    }
  }

  Future<void> _refreshJobMatch(Map<String, dynamic> job) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _selectedJob = job;
      _loadingJobMatch = true;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'extract-resume-text',
        body: {'userId': userId, 'jobId': job['id']},
      );
      if (response.data?['jobMatch'] != null && mounted) {
        setState(() => _jobMatch = Map<String, dynamic>.from(response.data['jobMatch']));
      }
    } catch (e) {
      debugPrint('Job match refresh failed: $e');
    } finally {
      if (mounted) setState(() => _loadingJobMatch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Resume Quality Score", style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: FutureBuilder<ResumeAnalysisData>(
        future: _generalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final analysis = snapshot.data ?? ResumeAnalysisData(hasResume: false, score: 0, checks: []);

          if (!analysis.hasResume) {
            return const ResumeScoreEmptyPrompt();
          }

          if (analysis.errorMessage != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  "Couldn't load analysis: ${analysis.errorMessage}",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              ResumeScoreHeroCard(score: analysis.score),
              SizedBox(height: AppSpacing.xl),
              ...analysis.checks.map((c) => ResumeScoreCheckTile(check: c)),
              SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text("CHECK MATCH FOR A SPECIFIC JOB", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              if (_jobs.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: AppDecorations.card(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      value: _selectedJob,
                      icon: Icon(Icons.expand_more, color: AppColors.primary),
                      items: _jobs.map((j) => DropdownMenuItem(
                        value: j,
                        child: Text("${j['title']} @ ${j['company']}", style: AppTypography.bodyMediumBold, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) _refreshJobMatch(v);
                      },
                    ),
                  ),
                ),
              SizedBox(height: AppSpacing.lg),
              ResumeScoreJobMatchCard(loading: _loadingJobMatch, jobMatch: _jobMatch),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
