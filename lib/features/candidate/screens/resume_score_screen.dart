import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ResumeScoreScreen extends StatefulWidget {
  const ResumeScoreScreen({super.key});
  @override
  State<ResumeScoreScreen> createState() => _ResumeScoreScreenState();
}

class _ResumeScoreScreenState extends State<ResumeScoreScreen> {
  late Future<_ResumeAnalysis> _generalFuture;
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _selectedJob;
  Map<String, dynamic>? _jobMatch;
  bool _loadingJobMatch = false;

  @override
  void initState() {
    super.initState();
    _generalFuture = _loadGeneralAnalysis();
  }

  Future<_ResumeAnalysis> _loadGeneralAnalysis() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return _ResumeAnalysis(hasResume: false, score: 0, checks: []);
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('resume_path')
        .eq('id', userId)
        .maybeSingle();

    final resumePath = profile?['resume_path'] as String?;
    if (resumePath == null || resumePath.isEmpty) {
      return _ResumeAnalysis(hasResume: false, score: 0, checks: []);
    }

    final jobsData = await Supabase.instance.client
        .from('jobs')
        .select('id, title, company, description')
        .order('title');
    _jobs = List<Map<String, dynamic>>.from(jobsData);
    if (_jobs.isNotEmpty) _selectedJob = _jobs.first;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'extract-resume-text',
        body: {'userId': userId, if (_selectedJob != null) 'jobId': _selectedJob!['id']},
      );

      if (response.data == null || response.data['error'] != null) {
        return _ResumeAnalysis(hasResume: true, score: 0, checks: [], errorMessage: response.data?['error']);
      }

      final general = response.data['general'] as Map<String, dynamic>?;
      final checks = (general?['checks'] as List<dynamic>? ?? [])
          .map((c) => Map<String, dynamic>.from(c))
          .toList();

      if (response.data['jobMatch'] != null) {
        _jobMatch = Map<String, dynamic>.from(response.data['jobMatch']);
      }

      return _ResumeAnalysis(hasResume: true, score: general?['score'] ?? 0, checks: checks);
    } catch (e) {
      return _ResumeAnalysis(hasResume: true, score: 0, checks: [], errorMessage: e.toString());
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
      if (response.data?['jobMatch'] != null) {
        setState(() => _jobMatch = Map<String, dynamic>.from(response.data['jobMatch']));
      }
    } catch (e) {
      debugPrint('Job match refresh failed: $e');
    } finally {
      if (mounted) setState(() => _loadingJobMatch = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
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
      body: FutureBuilder<_ResumeAnalysis>(
        future: _generalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final analysis = snapshot.data ?? _ResumeAnalysis(hasResume: false, score: 0, checks: []);

          if (!analysis.hasResume) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      "Upload a resume first to see your quality score.",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
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

          final scoreColor = _scoreColor(analysis.score);

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              // --- HERO SCORE CARD ---
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
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: CircularProgressIndicator(
                              value: analysis.score / 100,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(scoreColor == AppColors.error ? Colors.orangeAccent : Colors.greenAccent),
                            ),
                          ),
                          Text("${analysis.score}%",
                              style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("RESUME ANALYSIS", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 2)),
                          SizedBox(height: AppSpacing.xs),
                          Text("Quality Report", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20)),
                          SizedBox(height: AppSpacing.xs),
                          Text("Based on your uploaded resume", style: AppTypography.caption.copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // --- CHECKS ---
              ...analysis.checks.map((c) {
                final passed = c['passed'] == true;
                final checkColor = passed ? AppColors.success : AppColors.error;
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorderRadius.medium,
                    border: Border.all(color: checkColor.withValues(alpha: 0.18)),
                    boxShadow: [BoxShadow(color: checkColor.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(color: checkColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(passed ? Icons.check_rounded : Icons.close_rounded, color: checkColor, size: 18),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['label'] ?? '', style: AppTypography.bodyMediumBold),
                            Text(c['detail'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: AppDecorations.pill(checkColor),
                        child: Text(passed ? "PASS" : "MISSING",
                            style: AppTypography.captionBold.copyWith(color: checkColor)),
                      ),
                    ],
                  ),
                );
              }),

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
                      items: _jobs
                          .map((j) => DropdownMenuItem(
                                value: j,
                                child: Text(
                                  "${j['title']} @ ${j['company']}",
                                  style: AppTypography.bodyMediumBold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _refreshJobMatch(v);
                      },
                    ),
                  ),
                ),
              SizedBox(height: AppSpacing.lg),

              // --- JOB MATCH CARD ---
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, AppColors.primary.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.medium,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: _loadingJobMatch
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Icon(Icons.speed, size: 16, color: AppColors.primary),
                                SizedBox(width: AppSpacing.xs),
                                Text("JOB MATCH", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
                              ]),
                              Text("${_jobMatch?['matchPercent'] ?? 0}%",
                                  style: AppTypography.headlineLarge.copyWith(color: AppColors.primary, fontSize: 26)),
                            ],
                          ),
                          SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: AppBorderRadius.small,
                            child: LinearProgressIndicator(
                              value: ((_jobMatch?['matchPercent'] ?? 0) as int) / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text("Consider adding these keywords:", style: AppTypography.bodySmallBold),
                          SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: ((_jobMatch?['missingKeywords'] as List<dynamic>?) ?? [])
                                .map((kw) => Container(
                                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(kw.toString(),
                                          style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                                    ))
                                .toList(),
                          ),
                        ],
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

class _ResumeAnalysis {
  final bool hasResume;
  final int score;
  final List<Map<String, dynamic>> checks;
  final String? errorMessage;
  _ResumeAnalysis({required this.hasResume, required this.score, required this.checks, this.errorMessage});
}
