// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

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
    final apps = await Supabase.instance.client
        .from('applications')
        .select('id, user_id, job_title, company_name, profiles(full_name)')
        .eq('status', 'shortlisted');
    final appRows = List<Map<String, dynamic>>.from(apps);

    final scheduled = await Supabase.instance.client.from('interview_schedules').select('application_id');
    final scheduledIds = List<Map<String, dynamic>>.from(scheduled).map((s) => s['application_id']).toSet();

    return appRows.where((a) => !scheduledIds.contains(a['id'])).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchScheduled() async {
    final data = await Supabase.instance.client
        .from('interview_schedules')
        .select('*')
        .order('scheduled_date');
    return List<Map<String, dynamic>>.from(data);
  }

  void _refresh() {
    setState(() {
      _unscheduledFuture = _fetchUnscheduledShortlisted();
      _scheduledFuture = _fetchScheduled();
    });
  }

  Future<void> _openScheduleForm(Map<String, dynamic> application) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedRound = _rounds.first;
    String selectedMode = _modes.first;
    final linkOrLocationCtrl = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Schedule Interview", style: AppTypography.titleMedium),
                    IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close)),
                  ],
                ),
                Text("${application['profiles']?['full_name'] ?? 'Candidate'} \u2014 ${application['job_title']}",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                const Divider(),
                SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setSheetState(() => selectedDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Interview Date",
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.lightBlue, size: 18),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                    ),
                    child: Text(
                      selectedDate == null
                          ? "Select date"
                          : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (picked != null) setSheetState(() => selectedTime = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Interview Time",
                      labelStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.access_time, color: Colors.lightBlue, size: 18),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                    ),
                    child: Text(
                      selectedTime == null ? "Select time" : selectedTime!.format(ctx),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedRound,
                  style: TextStyle(color: AppColors.textPrimary),
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: "Round",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.flag_outlined, color: Colors.lightBlue, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                  items: _rounds.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setSheetState(() => selectedRound = v ?? _rounds.first),
                ),
                SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  style: TextStyle(color: AppColors.textPrimary),
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: "Mode",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.videocam_outlined, color: Colors.lightBlue, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                  items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setSheetState(() => selectedMode = v ?? _modes.first),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: linkOrLocationCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: selectedMode == 'In-Person' ? "Location" : "Meeting Link",
                    labelStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(
                      selectedMode == 'In-Person' ? Icons.location_on_outlined : Icons.link,
                      color: Colors.lightBlue,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("CONFIRM SCHEDULE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;
    if (selectedDate == null || selectedTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Date and time are required.")),
        );
      }
      return;
    }

    try {
      await Supabase.instance.client.from('interview_schedules').insert({
        'application_id': application['id'],
        'candidate_id': application['user_id'],
        'job_title': application['job_title'],
        'company_name': application['company_name'],
        'scheduled_date': selectedDate!.toIso8601String().split('T').first,
        'scheduled_time': selectedTime!.format(context),
        'round_type': selectedRound,
        'mode': selectedMode,
        'meeting_link': selectedMode != 'In-Person' ? linkOrLocationCtrl.text.trim() : null,
        'location': selectedMode == 'In-Person' ? linkOrLocationCtrl.text.trim() : null,
        'status': 'scheduled',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Interview scheduled successfully"), backgroundColor: AppColors.success),
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

  Future<void> _cancelSchedule(int id) async {
    try {
      await Supabase.instance.client.from('interview_schedules').update({'status': 'cancelled'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Interview cancelled"), backgroundColor: AppColors.warning),
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
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0C4A6E), Colors.lightBlue]),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("INTERVIEW SCHEDULER", style: AppTypography.sectionHeader.copyWith(color: Colors.lightBlue.shade100)),
                    SizedBox(height: AppSpacing.xs),
                    Text("${scheduled.length} Upcoming Interviews", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18)),
                    Text("Real scheduling for shortlisted candidates", style: AppTypography.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text("NEEDS SCHEDULING", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (unscheduled.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No shortlisted candidates awaiting scheduling.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else
                ...unscheduled.map((a) => Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorderRadius.medium,
                        border: Border.all(color: Colors.lightBlue.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['profiles']?['full_name'] ?? 'Candidate', style: AppTypography.bodyMediumBold),
                                Text(a['job_title'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _openScheduleForm(a),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade700,
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text("SCHEDULE"),
                          ),
                        ],
                      ),
                    )),
              SizedBox(height: AppSpacing.xxl),
              Text("UPCOMING INTERVIEWS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              if (scheduled.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(),
                  child: Text("No interviews scheduled yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                )
              else
                ...scheduled.map((s) => Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppBorderRadius.medium,
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s['job_title'] ?? 'N/A',
                                  style: AppTypography.bodyMediumBold,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: AppDecorations.pill(AppColors.success),
                                child: Text(s['round_type'] ?? 'N/A', style: AppTypography.captionBold.copyWith(color: AppColors.success)),
                              ),
                            ],
                          ),
                          Text(s['company_name'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                          SizedBox(height: AppSpacing.sm),
                          Row(children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.lightBlue),
                            SizedBox(width: AppSpacing.xs),
                            Text("${s['scheduled_date']} at ${s['scheduled_time']}", style: AppTypography.bodySmall),
                          ]),
                          Row(children: [
                            Icon(s['mode'] == 'In-Person' ? Icons.location_on_outlined : Icons.videocam_outlined,
                                size: 14, color: Colors.lightBlue),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                "${s['mode']}${(s['meeting_link'] ?? s['location'] ?? '').toString().isNotEmpty ? ' \u2022 ${s['meeting_link'] ?? s['location']}' : ''}",
                                style: AppTypography.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                          SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _cancelSchedule(s['id']),
                              child: Text("Cancel", style: TextStyle(color: AppColors.error)),
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }
}
