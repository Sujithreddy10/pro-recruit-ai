import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key});
  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  late Future<void> _initialLoad;
  List<Map<String, dynamic>> _mySkills = [];
  String _resumeText = '';
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _selectedJob;

  int _readinessPercent = 0;
  List<String> _matchedKeywords = [];
  List<Map<String, String>> _gaps = []; // {skill, reason}
  bool _loadingGap = false;
  String? _gapError;

  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
    'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does',
    'will', 'would', 'should', 'could', 'this', 'that', 'these', 'those', 'we', 'you', 'i',
    'as', 'by', 'from', 'up', 'about', 'into', 'through', 'during', 'our', 'your', 'their'
  };

  @override
  void initState() {
    super.initState();
    _initialLoad = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final skills = await Supabase.instance.client
        .from('candidate_skills')
        .select('skill_name, category, proficiency')
        .eq('user_id', userId);
    _mySkills = List<Map<String, dynamic>>.from(skills);

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('resume_text')
        .eq('id', userId)
        .maybeSingle();
    _resumeText = (profile?['resume_text'] ?? '').toString();

    final jobsData = await Supabase.instance.client
        .from('jobs')
        .select('id, title, company, description')
        .order('title');
    _jobs = List<Map<String, dynamic>>.from(jobsData);

    if (_jobs.isNotEmpty) {
      await _analyzeJob(_jobs.first);
    }
  }

  List<String> _extractKeywords(String text, {int limit = 20}) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !_stopWords.contains(w));

    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  Future<void> _analyzeJob(Map<String, dynamic> job) async {
    setState(() {
      _selectedJob = job;
      _loadingGap = true;
      _gapError = null;
      _gaps = [];
    });

    final jobText = "${job['title'] ?? ''} ${job['description'] ?? ''}";
    final jobKeywords = _extractKeywords(jobText);

    final knownText = '${_mySkills.map((s) => s['skill_name'].toString()).join(' ')} $_resumeText'.toLowerCase();

    final matched = jobKeywords.where((k) => knownText.contains(k)).toList();
    final missing = jobKeywords.where((k) => !knownText.contains(k)).take(6).toList();

    final percent = jobKeywords.isEmpty ? 0 : ((matched.length / jobKeywords.length) * 100).round();

    setState(() {
      _matchedKeywords = matched;
      _readinessPercent = percent;
    });

    if (missing.isEmpty) {
      setState(() => _loadingGap = false);
      return;
    }

    try {
      // Calls the Supabase Edge Function 'skill-gap', which holds the
      // Gemini API key server-side. The key never ships inside the app.
      final response = await Supabase.instance.client.functions.invoke(
        'skill-gap',
        body: {
          'jobTitle': job['title'],
          'missingSkills': missing,
        },
      );

      if (response.status != 200) {
        throw 'Server error (${response.status})';
      }

      final data = response.data as Map<String, dynamic>;
      final gapsList = data['gaps'] as List<dynamic>;

      setState(() {
        _gaps = gapsList.map((e) => {'skill': e['skill'].toString(), 'reason': e['reason'].toString()}).toList();
        _loadingGap = false;
      });
    } catch (e) {
      setState(() {
        _gapError = e.toString();
        _gaps = missing.map((m) => {'skill': m, 'reason': ''}).toList();
        _loadingGap = false;
      });
    }
  }

  Color _readinessColor(int percent) {
    if (percent >= 70) return AppColors.success;
    if (percent >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("AI Skill-Gap Analytics", style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initialLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_jobs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text("No jobs available to compare against yet.",
                    textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
              ),
            );
          }

          final readinessColor = _readinessColor(_readinessPercent);

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, Colors.indigo.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
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
                              value: _readinessPercent / 100,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(readinessColor == AppColors.error ? Colors.orangeAccent : Colors.greenAccent),
                            ),
                          ),
                          Text("$_readinessPercent%", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SKILL READINESS", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 2)),
                          SizedBox(height: AppSpacing.xs),
                          Text("Based on your skills + resume", style: AppTypography.caption.copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Row(children: [
                Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.xs),
                Text("TARGET ROLE", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
              ]),
              SizedBox(height: AppSpacing.md),
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
                              child: Text("${j['title']} @ ${j['company']}",
                                  style: AppTypography.bodyMediumBold, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _analyzeJob(v);
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              if (_matchedKeywords.isNotEmpty) ...[
                Text("SKILLS YOU ALREADY HAVE", style: AppTypography.sectionHeader),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _matchedKeywords
                      .map((k) => Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: AppDecorations.pill(AppColors.success),
                            child: Text(k, style: AppTypography.captionBold.copyWith(color: AppColors.success)),
                          ))
                      .toList(),
                ),
                SizedBox(height: AppSpacing.xl),
              ],
              Row(children: [
                Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                SizedBox(width: AppSpacing.xs),
                Text("GAPS TO BRIDGE", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
              ]),
              SizedBox(height: AppSpacing.md),
              if (_loadingGap)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_gaps.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No gaps found for this role — nice work!",
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else
                ..._gaps.map((g) => Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.warning.withValues(alpha: 0.06), AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: AppBorderRadius.medium,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.14), shape: BoxShape.circle),
                              child: Icon(Icons.priority_high_rounded, color: AppColors.warning, size: 16),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Text(g['skill']!.toString().toUpperCase(),
                                style: AppTypography.bodyMediumBold.copyWith(color: AppColors.warning)),
                          ]),
                          if (g['reason']!.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: EdgeInsets.only(left: 44),
                              child: Text(g['reason']!, style: AppTypography.bodySmall),
                            ),
                          ],
                        ],
                      ),
                    )),
              if (_gapError != null) ...[
                SizedBox(height: AppSpacing.md),
                Text("Couldn't generate AI explanations: $_gapError", style: AppTypography.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
