import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class PipelineDashboardTab extends StatefulWidget {
  const PipelineDashboardTab({super.key});

  @override
  State<PipelineDashboardTab> createState() => _PipelineDashboardTabState();
}

class _PipelineDashboardTabState extends State<PipelineDashboardTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, int>> _pipelineFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pipelineFuture = _fetchPipelineCounts();
  }

  Future<Map<String, int>> _fetchPipelineCounts() async {
    final data = await Supabase.instance.client.from('applications').select('status');
    final rows = List<Map<String, dynamic>>.from(data);

    final counts = <String, int>{'applied': 0, 'shortlisted': 0, 'rejected': 0};
    for (final row in rows) {
      final status = row['status'] as String? ?? 'applied';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Widget _pipelineHeader(int total) => Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.primaryCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LIVE PIPELINE",
              style: AppTypography.sectionHeader.copyWith(color: Colors.cyanAccent),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              "Total Applications: $total",
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textLight,
                fontSize: 18,
              ),
            ),
            Text(
              "Real-time candidate status across all roles",
              style: AppTypography.caption.copyWith(color: Colors.white60),
            ),
          ],
        ),
      );

  Widget _pipelineStageCard(String title, String count, Color color, double progress) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.bodyMediumBold),
                Text(count, style: AppTypography.bodySmallBold.copyWith(color: color)),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppBorderRadius.small,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, int>>(
      future: _pipelineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
          );
        }
        final counts = snapshot.data ?? {'applied': 0, 'shortlisted': 0, 'rejected': 0};
        final total = counts.values.fold(0, (a, b) => a + b);
        double ratio(int v) => total == 0 ? 0 : v / total;

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _pipelineHeader(total),
            SizedBox(height: AppSpacing.xl),
            _pipelineStageCard(
              "Applied (Awaiting Review)",
              "${counts['applied']} Candidates",
              AppColors.info,
              ratio(counts['applied']!),
            ),
            _pipelineStageCard(
              "Shortlisted",
              "${counts['shortlisted']} Candidates",
              AppColors.success,
              ratio(counts['shortlisted']!),
            ),
            _pipelineStageCard(
              "Rejected",
              "${counts['rejected']} Candidates",
              AppColors.error,
              ratio(counts['rejected']!),
            ),
          ],
        );
      },
    );
  }
}
