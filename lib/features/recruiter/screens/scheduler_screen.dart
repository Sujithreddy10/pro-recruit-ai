// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/scheduler_widgets.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});
  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  late Future<List<Map<String, dynamic>>> _unscheduledFuture;
  late Future<List<Map<String, dynamic>>> _scheduledFuture;

  static const _rounds = ['Screening', 'Technical Round 1', 'Technical Round 2', 'Managerial', 'HR Final'];
  static const _modes = ['Video Call', 'Phone Call', 'In-Person'];

  @override
  void initState() {
    super.initState();
    _unscheduledFuture = _fetchUnscheduledShortlisted();
    _scheduledFuture = _fetchScheduled();
  }

  Future<List<Map<String, dynamic>>> _fetchUnscheduledShortlisted() async {
    final scheduledRes = await Supabase.instance.client
        .from('interview_schedules')
        .select('application_id')
        .neq('status', 'cancelled');
    final scheduledAppIds = (scheduledRes as List).map((r) => r['application_id']).toSet();

    final data = await Supabase.instance.client
        .from('applications')
        .select('id, user_id, job_title, company_name, profiles(id, full_name)')
        .eq('status', 'shortlisted')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data).where((a) => !scheduledAppIds.contains(a['id'])).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchScheduled() async {
    final data = await Supabase.instance.client
        .from('interview_schedules')
        .select()
        .order('scheduled_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  void _refresh() {
    setState(() {
      _unscheduledFuture = _fetchUnscheduledShortlisted();
      _scheduledFuture = _fetchScheduled();
    });
  }

  Future<void> _openScheduleForm(Map<String, dynamic> application) async {
    final candidateName = (application['profiles']?['full_name'] ?? 'Candidate').toString();
    final jobTitle = (application['job_title'] ?? 'N/A').toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => ScheduleInterviewSheet(
        candidateName: candidateName,
        jobTitle: jobTitle,
        rounds: _rounds,
        modes: _modes,
        onConfirm: (date, time, round, mode, linkOrLocation) async {
          Navigator.pop(ctx);
          try {
            await Supabase.instance.client.from('interview_schedules').insert({
              'application_id': application['id'],
              'candidate_id': application['user_id'],
              'job_title': application['job_title'],
              'company_name': application['company_name'],
              'scheduled_date': date.toIso8601String().split('T').first,
              'scheduled_time': time.format(context),
              'round_type': round,
              'mode': mode,
              'meeting_link': mode != 'In-Person' ? linkOrLocation : null,
              'location': mode == 'In-Person' ? linkOrLocation : null,
              'status': 'scheduled',
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text("Interview scheduled successfully"), backgroundColor: AppColors.success),
              );
              _refresh();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _cancelSchedule(int id) async {
    try {
      await Supabase.instance.client.from('interview_schedules').update({'status': 'cancelled'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Interview cancelled"), backgroundColor: AppColors.warning),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Scheduler", style: AppTypography.titleMedium.copyWith(color: Colors.lightBlue)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.lightBlue),
        elevation: 0,
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: Future.wait([_unscheduledFuture, _scheduledFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final unscheduled = snapshot.data?[0] ?? [];
          final scheduled = (snapshot.data?[1] ?? []).where((s) => s['status'] != 'cancelled').toList();

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              SchedulerHeader(scheduledCount: scheduled.length),
              SizedBox(height: AppSpacing.xl),
              Text("NEEDS SCHEDULING", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (unscheduled.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text(
                    "No shortlisted candidates awaiting scheduling.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                )
              else
                ...unscheduled.map(
                  (a) => NeedsSchedulingCard(
                    candidateName: (a['profiles']?['full_name'] ?? 'Candidate').toString(),
                    jobTitle: (a['job_title'] ?? 'N/A').toString(),
                    onSchedule: () => _openScheduleForm(a),
                  ),
                ),
              SizedBox(height: AppSpacing.xxl),
              Text("UPCOMING INTERVIEWS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (scheduled.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text(
                    "No interviews scheduled yet.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                )
              else
                ...scheduled.map(
                  (s) => UpcomingInterviewCard(
                    jobTitle: (s['job_title'] ?? 'N/A').toString(),
                    companyName: (s['company_name'] ?? 'N/A').toString(),
                    roundType: (s['round_type'] ?? 'N/A').toString(),
                    scheduledDate: (s['scheduled_date'] ?? '').toString(),
                    scheduledTime: (s['scheduled_time'] ?? '').toString(),
                    mode: (s['mode'] ?? 'N/A').toString(),
                    meetingLinkOrLocation: (s['meeting_link'] ?? s['location'])?.toString(),
                    onCancel: () => _cancelSchedule(s['id']),
                  ),
                ),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }
}
