import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class SalaryHubScreen extends StatefulWidget {
  const SalaryHubScreen({super.key});
  @override
  State<SalaryHubScreen> createState() => _SalaryHubScreenState();
}

class _SalaryHubScreenState extends State<SalaryHubScreen> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobsWithSalary();
  }

  Future<List<Map<String, dynamic>>> _fetchJobsWithSalary() async {
    final data = await Supabase.instance.client
        .from('jobs')
        .select('id, title, company, salary_range')
        .order('title');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("Salary Hub", style: AppTypography.titleMedium.copyWith(color: Colors.indigo)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.indigo),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(child: Text("No job listings found yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)));
          }
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.secondary, Color(0xFF312E81)]),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("LIVE MARKET BENCHMARKS", style: AppTypography.sectionHeader.copyWith(color: Colors.indigoAccent)),
                    SizedBox(height: AppSpacing.xs),
                    Text("${jobs.length} Active Job Postings", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18)),
                    Text("Real salary data across your open roles", style: AppTypography.caption.copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              ...jobs.map((j) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                          child: const Icon(Icons.business_center_outlined, color: Colors.indigo, size: 20),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(j['title'] ?? 'N/A', style: AppTypography.bodyMediumBold),
                              Text(j['company'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
                          child: Text(j['salary_range'] ?? 'N/A', style: AppTypography.bodySmallBold.copyWith(color: AppColors.success)),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
