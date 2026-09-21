import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_pipeline_cards.dart';
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

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              RecruiterPipelineHeader(total: total),
              SizedBox(height: AppSpacing.xl),
              RecruiterPipelineStageCard(
                title: "Applied (Awaiting Review)",
                count: "${counts['applied']} Candidates",
                accentColor: AppColors.info,
                progress: ratio(counts['applied']!),
              ),
              RecruiterPipelineStageCard(
                title: "Shortlisted",
                count: "${counts['shortlisted']} Candidates",
                accentColor: AppColors.success,
                progress: ratio(counts['shortlisted']!),
              ),
              RecruiterPipelineStageCard(
                title: "Rejected",
                count: "${counts['rejected']} Candidates",
                accentColor: AppColors.error,
                progress: ratio(counts['rejected']!),
              ),
            ],
          ),
        );
      },
    );
  }
}
