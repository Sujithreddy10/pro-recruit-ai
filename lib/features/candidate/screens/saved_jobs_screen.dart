import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  late Future<List<Map<String, dynamic>>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _savedFuture = _fetchSavedJobs();
  }

  void _refresh() {
    setState(() {
      _savedFuture = _fetchSavedJobs();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSavedJobs() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('saved_jobs')
        .select('id, job_id, jobs(id, title, company, mode, description, salary_range, logo_url, location)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _unsave(String savedRowId) async {
    try {
      await Supabase.instance.client.from('saved_jobs').delete().eq('id', savedRowId);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Saved Jobs", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _savedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final saved = snapshot.data ?? [];
          if (saved.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  SizedBox(height: AppSpacing.md),
                  Text("No saved jobs yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: saved.length,
            itemBuilder: (context, i) {
              final row = saved[i];
              final job = row['jobs'] as Map<String, dynamic>? ?? {};
              return Container(
                margin: EdgeInsets.only(bottom: AppSpacing.lg),
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorderRadius.large,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)]),
                        borderRadius: AppBorderRadius.small,
                      ),
                      child: (job['logo_url'] != null && job['logo_url'].toString().isNotEmpty)
                          ? Image.network(job['logo_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.business_rounded, color: AppColors.primary, size: 24))
                          : Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(job['title'] ?? 'N/A', style: AppTypography.titleMedium),
                        Text(job['company'] ?? 'N/A', style: AppTypography.bodySmallBold.copyWith(color: AppColors.primary)),
                        if ((job['location'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 2),
                              Text(job['location'], style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                            ]),
                          ),
                      ]),
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark, color: AppColors.primary),
                      onPressed: () => _unsave(row['id'].toString()),
                      tooltip: "Remove from saved",
                    ),
                  ]),
                  Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.border)),
                  Text(job['description'] ?? '', style: AppTypography.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
