import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class KPIAnalyticsScreen extends StatefulWidget {
  const KPIAnalyticsScreen({super.key});

  @override
  State<KPIAnalyticsScreen> createState() => _KPIAnalyticsScreenState();
}

class _KPIAnalyticsScreenState extends State<KPIAnalyticsScreen> {
  late Future<Map<String, dynamic>> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = _fetchKPIData();
  }

  Future<Map<String, dynamic>> _fetchKPIData() async {
    final client = Supabase.instance.client;
    final data = await client.from('applications').select('status, job_title, created_at, status_updated_at');
    final rows = List<Map<String, dynamic>>.from(data);

    final statusCounts = <String, int>{'applied': 0, 'shortlisted': 0, 'offer_sent': 0, 'hired': 0, 'rejected': 0};
    final jobCounts = <String, int>{};
    final hireDurations = <int>[];

    for (final row in rows) {
      final status = row['status'] as String? ?? 'applied';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final job = row['job_title'] as String? ?? 'Unknown Role';
      jobCounts[job] = (jobCounts[job] ?? 0) + 1;

      if (status == 'hired' && row['created_at'] != null && row['status_updated_at'] != null) {
        final applied = DateTime.tryParse(row['created_at']);
        final hired = DateTime.tryParse(row['status_updated_at']);
        if (applied != null && hired != null) {
          hireDurations.add(hired.difference(applied).inDays);
        }
      }
    }

    final total = rows.length;
    final sortedJobs = jobCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final avgDaysToHire = hireDurations.isEmpty
        ? null
        : (hireDurations.reduce((a, b) => a + b) / hireDurations.length).round();

    return {
      'total': total,
      'statusCounts': statusCounts,
      'topJobs': sortedJobs.take(5).toList(),
      'avgDaysToHire': avgDaysToHire,
    };
  }

  String _pct(int count, int total) => total == 0 ? '0%' : '${((count / total) * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("KPI Analytics", style: AppTypography.titleMedium.copyWith(color: Colors.pinkAccent)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _kpiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final data = snapshot.data!;
          final total = data['total'] as int;
          final counts = data['statusCounts'] as Map<String, int>;
          final topJobs = data['topJobs'] as List<MapEntry<String, int>>;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Text("CONVERSION FUNNEL", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.xs),
              Text("Based on $total total applications", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              SizedBox(height: AppSpacing.md),
              _funnelStage("Applied", counts['applied']! + counts['shortlisted']! + counts['offer_sent']! + counts['hired']!, total, AppColors.info),
              _funnelStage("Shortlisted", counts['shortlisted']! + counts['offer_sent']! + counts['hired']!, total, AppColors.warning),
              _funnelStage("Offer Sent", counts['offer_sent']! + counts['hired']!, total, Colors.purple),
              _funnelStage("Hired", counts['hired']!, total, AppColors.success),
              SizedBox(height: AppSpacing.xxl),
              Text("APPLICATIONS PER ROLE", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (topJobs.isEmpty)
                Text("No applications yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
              else
                ...topJobs.map((e) => _jobBar(e.key, e.value, topJobs.first.value)),
              SizedBox(height: AppSpacing.lg),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius: AppBorderRadius.medium,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.success, size: 22),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("AVG. TIME TO HIRE", style: AppTypography.sectionHeader.copyWith(color: AppColors.textDark)),
                          Text(
                            data['avgDaysToHire'] == null
                                ? "Not enough hired data yet"
                                : "${data['avgDaysToHire']} days from application to hire",
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _funnelStage(String label, int count, int total, Color color) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: AppTypography.bodyMediumBold),
              Text("$count (${_pct(count, total)})", style: AppTypography.bodySmallBold.copyWith(color: color)),
            ]),
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppBorderRadius.small,
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _jobBar(String job, int count, int maxCount) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(job, style: AppTypography.bodySmallBold)),
              Text("$count", style: AppTypography.bodySmallBold),
            ]),
            SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppBorderRadius.small,
              child: LinearProgressIndicator(
                value: maxCount == 0 ? 0 : count / maxCount,
                minHeight: 5,
                backgroundColor: AppColors.surfaceVariant,
                color: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      );
}
