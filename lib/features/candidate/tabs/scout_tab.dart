import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';

class ScoutTab extends StatefulWidget {
  const ScoutTab({super.key});

  @override
  State<ScoutTab> createState() => _ScoutTabState();
}

class _ScoutTabState extends State<ScoutTab> with AutomaticKeepAliveClientMixin {
  String _searchQuery = "";
  final Set<String> _selectedLocations = {};
  final Set<String> _selectedWorkModes = {};
  final Set<String> _appliedJobs = {};
  final Set<String> _savedJobIds = {};
  final Set<String> _viewedJobIds = {};
  bool _viewingApplications = false;

  late Future<List<Map<String, dynamic>>> _jobsFuture;

  final List<Color> _jobAccentColors = [
    AppColors.primary,
    Colors.indigo,
    Colors.teal,
    Colors.deepPurple,
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
    _jobsFuture.then((jobs) => _trackJobViews(jobs));
    _loadSavedJobIds();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    return await Supabase.instance.client.from('jobs').select('*');
  }

  void _trackJobViews(List<Map<String, dynamic>> jobs) {
    for (final job in jobs) {
      final jobId = (job['id'] ?? '').toString();
      if (jobId.isEmpty || _viewedJobIds.contains(jobId)) continue;
      _viewedJobIds.add(jobId);
      Supabase.instance.client.rpc('increment_job_view', params: {'job_id_param': jobId}).catchError((_) {});
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
    return List<Map<String, dynamic>>.from(data).map((r) => r['job_id'].toString()).toSet();
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isSaved = _savedJobIds.contains(jobId);
    setState(() {
      if (isSaved) {
        _savedJobIds.remove(jobId);
      } else {
        _savedJobIds.add(jobId);
      }
    });
    try {
      if (isSaved) {
        await Supabase.instance.client.from('saved_jobs').delete().eq('user_id', userId).eq('job_id', jobId);
      } else {
        await Supabase.instance.client.from('saved_jobs').insert({'user_id': userId, 'job_id': jobId});
      }
    } catch (e) {
      setState(() {
        if (isSaved) {
          _savedJobIds.add(jobId);
        } else {
          _savedJobIds.remove(jobId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update saved jobs: $e")));
      }
    }
  }

  Future<void> _startOrOpenConversation(String recruiterId, String jobTitle, String companyName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || recruiterId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .upsert(
            {
              'candidate_id': userId,
              'recruiter_id': recruiterId,
              'job_title': jobTitle,
              'company_name': companyName,
            },
            onConflict: 'candidate_id,recruiter_id',
          )
          .select('id')
          .single();
      final conversationId = row['id'].toString();
      final recruiterProfile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', recruiterId)
          .maybeSingle();
      final recruiterName = recruiterProfile?['full_name'] ?? 'Recruiter';
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ChatScreen(
              conversationId: conversationId,
              otherPartyName: recruiterName,
              contextLabel: "$jobTitle · $companyName",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open conversation: $e")));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMyApplications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> _fetchMyPerformanceData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'applied_count': 0, 'profile_score': 0};

    final apps = await Supabase.instance.client.from('applications').select('id').eq('user_id', userId);
    final profile = await Supabase.instance.client.from('profiles').select('full_name, resume_path').eq('id', userId).maybeSingle() ?? {};
    final hasName = (profile['full_name'] ?? '').toString().isNotEmpty;
    final hasResume = (profile['resume_path'] ?? '').toString().isNotEmpty;
    final passed = (hasName ? 1 : 0) + (hasResume ? 1 : 0);
    final score = ((passed / 2) * 100).round();

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

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _profilePerformanceRadar(),
            SizedBox(height: AppSpacing.xl),
            _smartSearchBar(),
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _viewingApplications = false),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                                gradient: !_viewingApplications
                                    ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
                                    : null,
                                color: !_viewingApplications ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: !_viewingApplications
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                    : null),
                            child: Center(
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.explore_outlined, size: 14, color: !_viewingApplications ? AppColors.textLight : AppColors.textMuted),
                              SizedBox(width: AppSpacing.xs),
                              Text("JOB FEED",
                                  style: AppTypography.captionBold.copyWith(
                                      color: !_viewingApplications ? AppColors.textLight : AppColors.textMuted)),
                            ]))))),
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _viewingApplications = true),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                                gradient: _viewingApplications
                                    ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary])
                                    : null,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _viewingApplications
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                    : null),
                            child: Center(
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.assignment_turned_in_outlined, size: 14, color: _viewingApplications ? AppColors.textLight : AppColors.textMuted),
                              SizedBox(width: AppSpacing.xs),
                              Text("MY APPLICATIONS",
                                  style: AppTypography.captionBold.copyWith(
                                      color: _viewingApplications ? AppColors.textLight : AppColors.textMuted)),
                            ]))))),
              ]),
            ),
            SizedBox(height: AppSpacing.xl),
            if (!_viewingApplications) ...[
              _filterHub(),
              SizedBox(height: AppSpacing.md),
              if (filteredJobs.isEmpty)
                Center(
                    child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Column(children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          SizedBox(height: AppSpacing.md),
                          Text("No Elite Jobs match your search.",
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        ])))
              else
                ...filteredJobs.asMap().entries.map((entry) => _jobCard(
                    id: (entry.value['id'] ?? '').toString(),
                    recruiterId: (entry.value['recruiter_id'] ?? '').toString(),
                    entry.value['title'] ?? 'N/A',
                    entry.value['company'] ?? 'N/A',
                    entry.value['mode'] ?? 'Hybrid',
                    entry.value['description'] ?? '',
                    _jobAccentColors[entry.key % _jobAccentColors.length],
                    logoUrl: entry.value['logo_url'],
                    location: entry.value['location'])),
            ] else ...[
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchMyApplications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  final myApps = snapshot.data ?? [];
                  if (myApps.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Column(children: [
                          Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          SizedBox(height: AppSpacing.md),
                          Text("You haven't applied to any jobs yet.",
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        ]),
                      ),
                    );
                  }
                  return Column(
                    children: myApps
                        .asMap()
                        .entries
                        .map((e) => _appHubCard(
                              e.value['company_name'] ?? 'N/A',
                              e.value['job_title'] ?? 'N/A',
                              _statusLabel(e.value['status'] ?? 'applied'),
                              _statusProgress(e.value['status'] ?? 'applied'),
                              _jobAccentColors[e.key % _jobAccentColors.length],
                            )).toList()
                        ,
                  );
                },
              ),
            ]
          ],
        );
      },
    );
  }

  Widget _profilePerformanceRadar() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMyPerformanceData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'applied_count': 0, 'profile_score': 0};
        final appliedCount = data['applied_count'] as int;
        final profileScore = data['profile_score'] as int;

        return Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, Colors.indigo.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppBorderRadius.large,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("YOUR ACTIVITY", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 1.6)),
              const Icon(Icons.query_stats, color: Colors.white54, size: 20),
            ]),
            SizedBox(height: AppSpacing.xl),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _insightStat("$appliedCount", "Applications Sent", Icons.search),
            ]),
            const Divider(color: Colors.white24, height: 30),
            Row(children: [
              Text("Profile Strength: $profileScore%", style: AppTypography.caption.copyWith(color: Colors.white70)),
              const Spacer(),
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CandidateProfileHub())),
                  child: Text("IMPROVE >", style: AppTypography.captionBold.copyWith(color: AppColors.accentAmber)))
            ]),
            SizedBox(height: AppSpacing.xs),
            ClipRRect(
                borderRadius: AppBorderRadius.small,
                child: LinearProgressIndicator(
                    value: profileScore / 100, backgroundColor: Colors.white12, color: Colors.greenAccent, minHeight: 6)),
          ]),
        );
      },
    );
  }

  Widget _insightStat(String val, String label, IconData icon) => Column(children: [
        Icon(icon, color: Colors.white60, size: 16),
        SizedBox(height: AppSpacing.xs),
        Text(val, style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight)),
        Text(label, style: AppTypography.caption.copyWith(color: Colors.white70)),
      ]);

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
              child: Text(status, style: AppTypography.caption.copyWith(color: c, fontWeight: FontWeight.bold)))
        ]),
        SizedBox(height: AppSpacing.xs),
        Text(role, style: AppTypography.titleMedium),
        SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppBorderRadius.small,
          child: LinearProgressIndicator(value: progress, color: c, backgroundColor: c.withValues(alpha: 0.1), minHeight: 6),
        ),
      ]));

  Widget _smartSearchBar() => Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10)]),
      child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
              hintText: "Search Roles...",
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none)));

  Widget _filterHub() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _filterChip("Locations", ["Hyderabad", "Chennai", "Bengaluru", "Kolkata", "Delhi", "Pune", "Gurgaon"], _selectedLocations),
        SizedBox(width: AppSpacing.sm),
        _filterChip("Work Mode", ["Hybrid", "Remote", "On-site"], _selectedWorkModes)
      ]));
  Widget _filterChip(String label, List<String> options, Set<String> selected) => ActionChip(
      label: Text(selected.isEmpty ? label : "$label (${selected.length})",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 11)),
      onPressed: () => _showFilterSheet(label, options, selected),
      avatar: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
      backgroundColor: selected.isEmpty ? Colors.white : AppColors.primary.withValues(alpha: 0.15));
  void _showFilterSheet(String title, List<String> options, Set<String> selected) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => StatefulBuilder(
            builder: (c, setSheetState) => Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                    if (selected.isNotEmpty)
                      TextButton(
                          onPressed: () => setSheetState(() => setState(() => selected.clear())),
                          child: const Text("Clear")),
                  ]),
                  const Divider(),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: options
                        .map((o) => FilterChip(
                              label: Text(o, style: const TextStyle(color: Colors.black87)),
                              selected: selected.contains(o),
                              backgroundColor: const Color(0xFFF1F5F9),
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppColors.primary,
                              onSelected: (v) => setSheetState(() => setState(() {
                                    if (v) {
                                      selected.add(o);
                                    } else {
                                      selected.remove(o);
                                    }
                                  })),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("Apply"),
                    ),
                  ),
                ]))));
  }

  Widget _jobCard(String t, String c, String mode, String d, Color accent, {required String id, required String recruiterId, String? logoUrl, String? location}) {
    bool applied = _appliedJobs.contains(t);
    return Container(
        margin: EdgeInsets.only(bottom: AppSpacing.lg),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.large,
          border: Border.all(color: accent.withValues(alpha: 0.12)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]),
                    borderRadius: AppBorderRadius.small),
                child: (logoUrl != null && logoUrl.isNotEmpty)
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(Icons.business_rounded, color: accent, size: 24),
                      )
                    : Icon(Icons.business_rounded, color: accent, size: 24)),
            SizedBox(width: AppSpacing.md),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: AppTypography.titleMedium),
              Text(c, style: AppTypography.bodySmallBold.copyWith(color: accent)),
              if (location != null && location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location,
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ])),
            _badge(mode, accent),
            IconButton(
              icon: Icon(_savedJobIds.contains(id) ? Icons.bookmark : Icons.bookmark_border, color: accent, size: 20),
              onPressed: () => _toggleSaveJob(id),
              tooltip: _savedJobIds.contains(id) ? 'Unsave' : 'Save job',
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: accent, size: 20),
              onPressed: () => _startOrOpenConversation(recruiterId, t, c),
              tooltip: 'Message Recruiter',
            ),
          ]),
          Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.border)),
          Text(d, style: AppTypography.bodyMedium),
          SizedBox(height: AppSpacing.md),
          Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: applied
                    ? null
                    : BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primaryDark, accent]),
                        borderRadius: AppBorderRadius.small,
                        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                child: TextButton(
                    onPressed: applied ? null : () => _showRTR(t, c),
                    style: TextButton.styleFrom(
                        backgroundColor: applied ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small)),
                    child: Text(applied ? "Applied ✓" : "Apply Now",
                        style: AppTypography.bodySmallBold.copyWith(color: applied ? AppColors.success : AppColors.textLight))),
              )),
        ]));
  }

  Widget _badge(String label, Color accent) => Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: AppDecorations.pill(accent),
      child: Text(label, style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.bold)));

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
                      .toList()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleApply(jobTitle, company);
                    },
                    child: const Text("Confirm & Apply"))
              ],
            ));
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

}
