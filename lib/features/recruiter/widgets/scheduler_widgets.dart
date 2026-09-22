import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class SchedulerHeader extends StatelessWidget {
  final int scheduledCount;

  const SchedulerHeader({super.key, required this.scheduledCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0C4A6E), Colors.lightBlue]),
        borderRadius: AppBorderRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INTERVIEW SCHEDULER",
            style: AppTypography.sectionHeader.copyWith(color: Colors.lightBlue.shade100),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            "$scheduledCount Upcoming Interviews",
            style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18),
          ),
          Text(
            "Real scheduling for shortlisted candidates",
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class NeedsSchedulingCard extends StatelessWidget {
  final String candidateName;
  final String jobTitle;
  final VoidCallback onSchedule;

  const NeedsSchedulingCard({
    super.key,
    required this.candidateName,
    required this.jobTitle,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(candidateName, style: AppTypography.bodyMediumBold),
                Text(jobTitle, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade700,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text("SCHEDULE"),
          ),
        ],
      ),
    );
  }
}

class UpcomingInterviewCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String roundType;
  final String scheduledDate;
  final String scheduledTime;
  final String mode;
  final String? meetingLinkOrLocation;
  final VoidCallback onCancel;

  const UpcomingInterviewCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.roundType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.mode,
    this.meetingLinkOrLocation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: AppTypography.bodyMediumBold,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: AppDecorations.pill(AppColors.success),
                child: Text(
                  roundType,
                  style: AppTypography.captionBold.copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
          Text(companyName, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.lightBlue),
              SizedBox(width: AppSpacing.xs),
              Text("$scheduledDate at $scheduledTime", style: AppTypography.bodySmall),
            ],
          ),
          Row(
            children: [
              Icon(
                mode == 'In-Person' ? Icons.location_on_outlined : Icons.videocam_outlined,
                size: 14,
                color: Colors.lightBlue,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "$mode${(meetingLinkOrLocation ?? '').isNotEmpty ? ' \u2022 $meetingLinkOrLocation' : ''}",
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCancel,
              child: Text("Cancel", style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleInterviewSheet extends StatefulWidget {
  final String candidateName;
  final String jobTitle;
  final List<String> rounds;
  final List<String> modes;
  final Function(DateTime date, TimeOfDay time, String round, String mode, String linkOrLocation) onConfirm;

  const ScheduleInterviewSheet({
    super.key,
    required this.candidateName,
    required this.jobTitle,
    required this.rounds,
    required this.modes,
    required this.onConfirm,
  });

  @override
  State<ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends State<ScheduleInterviewSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _selectedRound;
  late String _selectedMode;
  final _linkOrLocationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRound = widget.rounds.first;
    _selectedMode = widget.modes.first;
  }

  @override
  void dispose() {
    _linkOrLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Schedule Interview", style: AppTypography.titleMedium),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            Text(
              "${widget.candidateName} \u2014 ${widget.jobTitle}",
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const Divider(),
            SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Interview Date",
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.lightBlue, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                ),
                child: Text(
                  _selectedDate == null
                      ? "Select date"
                      : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Interview Time",
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.access_time, color: Colors.lightBlue, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
                ),
                child: Text(
                  _selectedTime == null ? "Select time" : _selectedTime!.format(context),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedRound,
              style: TextStyle(color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: "Round",
                labelStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.flag_outlined, color: Colors.lightBlue, size: 18),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
              ),
              items: widget.rounds.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRound = v ?? widget.rounds.first),
            ),
            SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedMode,
              style: TextStyle(color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                labelText: "Mode",
                labelStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.videocam_outlined, color: Colors.lightBlue, size: 18),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
              ),
              items: widget.modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _selectedMode = v ?? widget.modes.first),
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: _linkOrLocationCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: _selectedMode == 'In-Person' ? "Location" : "Meeting Link",
                labelStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(
                  _selectedMode == 'In-Person' ? Icons.location_on_outlined : Icons.link,
                  color: Colors.lightBlue,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedDate == null || _selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Date and time are required.")),
                    );
                    return;
                  }
                  widget.onConfirm(
                    _selectedDate!,
                    _selectedTime!,
                    _selectedRound,
                    _selectedMode,
                    _linkOrLocationCtrl.text.trim(),
                  );
                },
                child: const Text("CONFIRM SCHEDULE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
