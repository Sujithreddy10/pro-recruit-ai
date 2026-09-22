import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/job_detail_screen.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  late Future<List<Map<String, dynamic>>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    final response = await Supabase.instance.client
        .from('jobs')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Job Feed", style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  "Unable to load jobs: ${snapshot.error}",
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Text("No open roles at the moment.", style: AppTypography.bodyMedium),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _jobsFuture = _fetchJobs();
              });
            },
            child: ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final title = job['title']?.toString() ?? 'Open Role';
                final company = job['company']?.toString() ?? 'Company';
                final location = job['location']?.toString() ?? 'Remote';
                final salary = job['salary_range']?.toString() ?? job['salary']?.toString();

                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.medium,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(AppSpacing.md),
                    title: Text(title, style: AppTypography.bodyMediumBold),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        "$company • $location${salary != null ? ' • $salary' : ''}",
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
