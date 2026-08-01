import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class MarketValueEstimatorScreen extends StatefulWidget {
  const MarketValueEstimatorScreen({super.key});
  @override
  State<MarketValueEstimatorScreen> createState() => _MarketValueEstimatorScreenState();
}

class _MarketValueEstimatorScreenState extends State<MarketValueEstimatorScreen> {
  late Future<List<String>> _titlesFuture;
  String? _selectedTitle;
  List<Map<String, dynamic>> _matchingJobs = [];
  bool _loadingMatches = false;

  @override
  void initState() {
    super.initState();
    _titlesFuture = _fetchDistinctTitles();
  }

  Future<List<String>> _fetchDistinctTitles() async {
    final data = await Supabase.instance.client.from('jobs').select('title').order('title');
    final rows = List<Map<String, dynamic>>.from(data);
    final titles = rows.map((r) => r['title'].toString()).toSet().toList();
    titles.sort();
    if (titles.isNotEmpty) {
      _selectedTitle = titles.first;
      _fetchMatchingJobs(titles.first);
    }
    return titles;
  }

  Future<void> _fetchMatchingJobs(String title) async {
    setState(() => _loadingMatches = true);
    try {
      final data = await Supabase.instance.client
          .from('jobs')
          .select('id, title, company, mode, salary_range')
          .eq('title', title);
      setState(() {
        _matchingJobs = List<Map<String, dynamic>>.from(data);
        _loadingMatches = false;
      });
    } catch (e) {
      setState(() => _loadingMatches = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Market Value Estimator", style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.success),
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _titlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final titles = snapshot.data ?? [];

          if (titles.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text("No job postings available yet to benchmark against.",
                    textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF064E3B), AppColors.success]),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("REAL MARKET DATA", style: AppTypography.sectionHeader.copyWith(color: Colors.greenAccent, letterSpacing: 1.6)),
                    SizedBox(height: AppSpacing.xs),
                    Text("Benchmarked from live job postings", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 16)),
                    Text("Pulled directly from your platform's real jobs \u2014 no estimates or guesses.",
                        style: AppTypography.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Row(children: [
                Icon(Icons.work_outline, size: 18, color: AppColors.success),
                SizedBox(width: AppSpacing.xs),
                Text("SELECT ROLE", style: AppTypography.sectionHeader.copyWith(color: AppColors.success)),
              ]),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: AppDecorations.card(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTitle,
                    icon: Icon(Icons.expand_more, color: AppColors.success),
                    items: titles.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodyMediumBold))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedTitle = v);
                        _fetchMatchingJobs(v);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Row(children: [
                Icon(Icons.bar_chart, size: 18, color: AppColors.success),
                SizedBox(width: AppSpacing.xs),
                Text("MATCHING POSTINGS", style: AppTypography.sectionHeader.copyWith(color: AppColors.success)),
              ]),
              SizedBox(height: AppSpacing.md),
              if (_loadingMatches)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_matchingJobs.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No postings found for this role.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else ...[
                if (_matchingJobs.length == 1)
                  Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: AppBorderRadius.small),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text("Limited data \u2014 only 1 posting found for this exact role.",
                            style: AppTypography.caption.copyWith(color: AppColors.warning)),
                      ),
                    ]),
                  ),
                ..._matchingJobs.map((j) => Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorderRadius.medium,
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                            child: Icon(Icons.business_center_outlined, color: AppColors.success, size: 20),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(j['company'] ?? 'N/A', style: AppTypography.bodyMediumBold),
                                Text(j['mode'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: AppDecorations.pill(AppColors.success),
                            child: Text(j['salary_range'] ?? 'N/A', style: AppTypography.bodySmallBold.copyWith(color: AppColors.success)),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
