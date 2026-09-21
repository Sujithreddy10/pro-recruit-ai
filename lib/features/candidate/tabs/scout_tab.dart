import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_radar_card.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_filter_bar.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_job_card.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ScoutTab extends StatefulWidget {
  const ScoutTab({super.key});

  @override
  State<ScoutTab> createState() => _ScoutTabState();
}

class _ScoutTabState extends State<ScoutTab> with AutomaticKeepAliveClientMixin {
  final Set<String> _appliedJobs = {};
  final Set<String> _savedJobIds = {};
  String _searchQuery = '';
  final Set<String> _selectedLocations = {};
  final Set<String> _selectedWorkModes = {};
  bool _viewingApplications = false;

  late Future<List<Map<String, dynamic>>> _jobsFuture;
  late Future<List<Map<String, dynamic>>> _myApplicationsFuture;
  late Future<Map<String, dynamic>> _myPerformanceFuture;

  final List<Color> _accentPalette = [
    AppColors.accentAmber,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    Colors.purple,
    Colors.pinkAccent,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
    _myApplicationsFuture = _fetchMyApplications();
    _myPerformanceFuture = _fetchMyPerformanceData();
    _loadSavedJobIds();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    final data = await Supabase.instance.client.from('jobs').select().order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(data);
    _trackJobViews(list);
    return list;
  }

  void _trackJobViews(List<Map<String, dynamic>> jobs) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    for (final job in jobs) {
      final recruiterId = job['recruiter_id'];
      if (recruiterId != null) {
        Supabase.instance.client.rpc('increment_profile_views', params: {'target_user_id': recruiterId}).catchError((_) {});
      }
    }
  }

  Future<void> _loadSavedJobIds() async {
    final ids = await _fetchSavedJobIds();
    if (mounted) setState(() => _savedJobIds.addAll(ids));
  }

  Future<Set<String>> _fetchSavedJobIds() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {};
    final data = await Supabase.instance.client.from('saved_jobs').select('job_id').eq('user_id', userId);
    return (data as List).map((e) => e['job_id'].toString()).toSet();
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isSaved = _savedJobIds.contains(jobId);
    setState(() => isSaved ? _savedJobIds.remove(jobId) : _savedJobIds.add(jobId));

    try {
      if (isSaved) {
        await Supabase.instance.client.from('saved_jobs').delete().match({'user_id': userId, 'job_id': jobId});
      } else {
        await Supabase.instance.client.from('saved_jobs').insert({'user_id': userId, 'job_id': jobId});
      }
    } catch (_) {
      if (mounted) {
        setState(() => isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId));
      }
    }
  }

  Future<void> _startOrOpenConversation(String recruiterId, String jobTitle, String companyName) async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
      return;
    }

    try {
      final existing = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .or('and(user_a.eq.$myId,user_b.eq.$recruiterId),and(user_a.eq.$recruiterId,user_b.eq.$myId)')
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'];
      } else {
        final res = await Supabase.instance.client
            .from('conversations')
            .insert({'user_a': myId, 'user_b': recruiterId, 'last_message': "Inquired about $jobTitle at $companyName"})
            .select('id')
            .single();
        convId = res['id'];
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => ChatScreen(
            conversationId: convId,
            otherPartyName: companyName,
            contextLabel: "Hiring Manager - $jobTitle",
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open chat: $e")));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMyApplications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> _fetchMyPerformanceData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'applied_count': 0, 'profile_score': 0};

    final apps = await Supabase.instance.client.from('applications').select('id').eq('user_id', userId);
    final profile = await Supabase.instance.client.from('profiles').select().eq('id', userId).maybeSingle();

    int score = 40;
    if (profile != null) {
      if (profile['headline'] != null && profile['headline'].toString().isNotEmpty) score += 20;
      if (profile['skills'] != null && (profile['skills'] as List).isNotEmpty) score += 20;
      if (profile['resume_path'] != null && profile['resume_path'].toString().isNotEmpty) score += 20;
    }

    return {
      'applied_count': List.from(apps).length,
      'profile_score': score,
    };
  }

  double _statusProgress(String status) {
    switch (status) {
      case 'hired':
      case 'rejected':
        return 1.0;
      case 'offer_sent':
        return 0.75;
      case 'shortlisted':
        return 0.5;
      default:
        return 0.25;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hired':
        return 'Hired';
      case 'rejected':
        return 'Rejected';
      case 'offer_sent':
        return 'Offer Sent';
      case 'shortlisted':
        return 'Shortlisted';
      default:
        return 'Applied';
    }
  }

  Widget _appHubCard(String co, String role, String status, double progress, Color c) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withValues(alpha: 0.06), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: c.withValues(alpha: 0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(co, style: AppTypography.captionBold.copyWith(color: c)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: AppDecorations.pill(c),
              child: Text(status, style: AppTypography.caption.copyWith(color: c, fontWeight: FontWeight.bold)),
            )
          ]),
          SizedBox(height: AppSpacing.xs),
          Text(role, style: AppTypography.titleMedium),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppBorderRadius.small,
            child: LinearProgressIndicator(value: progress, color: c, backgroundColor: c.withValues(alpha: 0.1), minHeight: 6),
          ),
        ]),
      );

  void _showRTR(String jobTitle, String company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("RTR Confirmation", style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppData.rtrData.entries
              .map((e) => Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text("${e.key}: ", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      Text(e.value, style: AppTypography.bodySmallBold)
                    ]),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleApply(jobTitle, company);
            },
            child: const Text("Confirm & Apply"),
          )
        ],
      ),
    );
  }

  Future<void> _handleApply(String jobTitle, String company) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
      return;
    }

    try {
      await supabase.from('applications').insert({
        'user_id': userId,
        'job_title': jobTitle,
        'company_name': company,
        'status': 'applied',
        'created_at': DateTime.now().toIso8601String(),
        'status_updated_at': DateTime.now().toIso8601String(),
      });

      setState(() => _appliedJobs.add(jobTitle));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Sent!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }

        final jobs = snapshot.data ?? [];
        final filteredJobs = jobs.where((job) {
          final searchLower = _searchQuery.toLowerCase();
          final title = (job['title'] ?? '').toString().toLowerCase();
          final matchesSearch = title.contains(searchLower);
          final jobLocation = (job['location'] ?? '').toString();
          final matchesLocation = _selectedLocations.isEmpty || _selectedLocations.contains(jobLocation);
          final jobMode = (job['mode'] ?? '').toString();
          final matchesMode = _selectedWorkModes.isEmpty || _selectedWorkModes.contains(jobMode);
          return matchesSearch && matchesLocation && matchesMode;
        }).toList();

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              CandidateRadarCard(performanceFuture: _myPerformanceFuture),
              SizedBox(height: AppSpacing.xl),
              CandidateFilterBar(
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                selectedLocations: _selectedLocations,
                selectedWorkModes: _selectedWorkModes,
                onFiltersChanged: () => setState(() {}),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewingApplications = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: !_viewingApplications ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]) : null,
                            color: !_viewingApplications ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: !_viewingApplications
                                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore_outlined, size: 14, color: !_viewingApplications ? AppColors.textLight : AppColors.textMuted),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  "JOB FEED",
                                  style: AppTypography.captionBold.copyWith(
                                    color: !_viewingApplications ? AppColors.textLight : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewingApplications = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: _viewingApplications ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]) : null,
                            color: _viewingApplications ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: _viewingApplications
                                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 14, color: _viewingApplications ? AppColors.textLight : AppColors.textMuted),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  "APPLICATIONS",
                                  style: AppTypography.captionBold.copyWith(
                                    color: _viewingApplications ? AppColors.textLight : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              if (!_viewingApplications) ...[
                if (filteredJobs.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text("No jobs found matching your criteria.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                    ),
                  )
                else
                  ...filteredJobs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final job = entry.value;
                    final accent = _accentPalette[idx % _accentPalette.length];
                    final jobId = job['id'].toString();
                    final title = job['title'] ?? 'Role';
                    final company = job['company'] ?? 'Enterprise';

                    return CandidateJobCard(
                      id: jobId,
                      recruiterId: job['recruiter_id'] ?? '',
                      title: title,
                      company: company,
                      mode: job['mode'] ?? 'Remote',
                      description: job['description'] ?? '',
                      location: job['location'],
                      logoUrl: job['logo_url'],
                      accent: accent,
                      isSaved: _savedJobIds.contains(jobId),
                      isApplied: _appliedJobs.contains(title),
                      onToggleSave: () => _toggleSaveJob(jobId),
                      onStartConversation: () => _startOrOpenConversation(job['recruiter_id'] ?? '', title, company),
                      onApply: () => _showRTR(title, company),
                    );
                  }),
              ] else ...[
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _myApplicationsFuture,
                  builder: (context, appSnap) {
                    if (appSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final myApps = appSnap.data ?? [];
                    if (myApps.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Text("No active applications yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        ),
                      );
                    }
                    return Column(
                      children: myApps.asMap().entries.map((e) {
                        final i = e.key;
                        final a = e.value;
                        final c = _accentPalette[i % _accentPalette.length];
                        final rawStatus = a['status'] ?? 'applied';
                        return _appHubCard(
                          a['company_name'] ?? 'Enterprise',
                          a['job_title'] ?? 'Role',
                          _statusLabel(rawStatus),
                          _statusProgress(rawStatus),
                          c,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
