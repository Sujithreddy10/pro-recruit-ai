import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class JobAlertPreferencesScreen extends StatefulWidget {
  const JobAlertPreferencesScreen({super.key});

  @override
  State<JobAlertPreferencesScreen> createState() => _JobAlertPreferencesScreenState();
}

class _JobAlertPreferencesScreenState extends State<JobAlertPreferencesScreen> {
  static const _modes = ['Hybrid', 'Remote', 'On-site'];
  final Set<String> _selectedModes = {};
  final TextEditingController _locationsCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('job_alert_preferences')
          .select('locations, work_modes')
          .eq('user_id', userId)
          .maybeSingle();
      if (data != null) {
        final modes = List<String>.from(data['work_modes'] ?? []);
        final locations = List<String>.from(data['locations'] ?? []);
        setState(() {
          _selectedModes.addAll(modes);
          _locationsCtrl.text = locations.join(', ');
        });
      }
    } catch (e) {
      // ignore, leave defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final locations = _locationsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    try {
      await Supabase.instance.client.from('job_alert_preferences').upsert(
        {
          'user_id': userId,
          'locations': locations,
          'work_modes': _selectedModes.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job alert preferences saved.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Job Alerts", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Get notified the moment a new job matching your preferences is posted.",
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text("Work Mode", style: AppTypography.bodySmallBold),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: _modes
                        .map((m) => FilterChip(
                              label: Text(m),
                              selected: _selectedModes.contains(m),
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _selectedModes.add(m);
                                } else {
                                  _selectedModes.remove(m);
                                }
                              }),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text("Preferred Locations", style: AppTypography.bodySmallBold),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "Comma-separated, e.g. Bengaluru, Hyderabad, Remote",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _locationsCtrl,
                    decoration: const InputDecoration(
                      hintText: "e.g. Bengaluru, Hyderabad",
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text(
                    "Leave both empty to get alerts for every new job.",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _savePreferences,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Save Preferences"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
