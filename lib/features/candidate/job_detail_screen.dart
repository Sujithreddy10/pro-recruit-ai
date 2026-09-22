import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;
  int? _matchScore;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
    _loadMatchScore();
  }

  Future<void> _checkApplicationStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final jobTitle = widget.job['title']?.toString() ?? '';
    final company = widget.job['company']?.toString() ?? '';

    try {
      final existing = await Supabase.instance.client
          .from('applications')
          .select('id')
          .eq('user_id', userId)
          .eq('job_title', jobTitle)
          .eq('company_name', company)
          .maybeSingle();

      if (existing != null && mounted) {
        setState(() => _hasApplied = true);
      }
    } catch (_) {}
  }

  Future<void> _loadMatchScore() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final jobId = widget.job['id'];
    if (userId == null || jobId == null) return;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'extract-resume-text',
        body: {'userId': userId, 'jobId': jobId},
      );
      if (response.data?['jobMatch']?['matchPercentage'] != null && mounted) {
        setState(() {
          _matchScore = (response.data['jobMatch']['matchPercentage'] as num).toInt();
        });
      }
    } catch (_) {}
  }

  Future<void> _applyForJob() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to apply")),
      );
      return;
    }

    setState(() => _isApplying = true);

    final jobTitle = widget.job['title']?.toString() ?? 'Role';
    final company = widget.job['company']?.toString() ?? 'Company';

    try {
      await Supabase.instance.client.from('applications').insert({
        'user_id': userId,
        'job_title': jobTitle,
        'company_name': company,
        'status': 'applied',
        'created_at': DateTime.now().toIso8601String(),
        'status_updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() => _hasApplied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application successfully submitted!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Application failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.job['title']?.toString() ?? 'Role Details';
    final company = widget.job['company']?.toString() ?? 'Company';
    final location = widget.job['location']?.toString() ?? 'Remote';
    final description = widget.job['description']?.toString() ?? 'No detailed description provided.';

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Job Details", style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineLarge),
                SizedBox(height: AppSpacing.xs),
                Text("$company • $location", style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (_matchScore != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppBorderRadius.medium,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.success, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    "AI Match Score: $_matchScore%",
                    style: AppTypography.bodyMediumBold.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppSpacing.lg),
          Text("JOB DESCRIPTION", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(),
            child: Text(description, style: AppTypography.bodyMedium),
          ),
          SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: (_hasApplied || _isApplying) ? null : _applyForJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasApplied ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
            ),
            child: _isApplying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _hasApplied ? "Already Applied" : "Apply Now",
                    style: AppTypography.bodyMediumBold.copyWith(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
