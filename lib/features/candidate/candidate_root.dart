import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/features/candidate/screens/resume_score_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/skill_gap_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/elite_certificates_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/resume_vault_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/market_value_estimator_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/pitch_analysis_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- CANDIDATE ROOT (THE MASTER LAYOUT) ---
class CandidateRoot extends StatefulWidget {
  const CandidateRoot({super.key});
  @override
  State<CandidateRoot> createState() => _CandidateRootState();
}

class _CandidateRootState extends State<CandidateRoot> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 30),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: const MainNavigation(),
    );
  }
}

// --- MAIN NAVIGATION SYSTEM ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = "";
  final Set<String> _appliedJobs = {};
  bool _isShowingLeaderboard = false;
  bool _viewingApplications = false;

  late Future<List<Map<String, dynamic>>> _jobsFuture;

  final List<Color> _jobAccentColors = [
    AppColors.primary,
    Colors.indigo,
    Colors.teal,
    Colors.deepPurple,
  ];

  @override
  void initState() {
    super.initState();
    _jobsFuture = _fetchJobs();
  }

  Future<List<Map<String, dynamic>>> _fetchJobs() async {
    return await Supabase.instance.client.from('jobs').select('*');
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

  Future<List<Map<String, dynamic>>> _fetchTopRecruiters() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name')
        .eq('user_role', 'recruiter')
        .limit(5);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('user_id, profiles(full_name)')
        .eq('status', 'shortlisted');
    final rows = List<Map<String, dynamic>>.from(data);

    final counts = <String, int>{};
    final names = <String, String>{};
    for (final row in rows) {
      final uid = row['user_id'] as String;
      counts[uid] = (counts[uid] ?? 0) + 1;
      names[uid] = row['profiles']?['full_name'] ?? 'Candidate';
    }

    final list = counts.entries
        .map((e) => {'user_id': e.key, 'name': names[e.key] ?? 'Candidate', 'count': e.value})
        .toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(5).toList();
  }

  Future<Map<String, dynamic>> _fetchMyTrustData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'full_name': '', 'resume_path': null};

    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name, resume_path')
        .eq('id', userId)
        .maybeSingle();

    return data ?? {'full_name': '', 'resume_path': null};
  }

  Future<Map<String, dynamic>> _fetchMyPerformanceData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'applied_count': 0, 'profile_score': 0};

    final apps = await Supabase.instance.client
        .from('applications')
        .select('id')
        .eq('user_id', userId);

    final profile = await _fetchMyTrustData();
    final hasName = (profile['full_name'] ?? '').toString().isNotEmpty;
    final hasResume = (profile['resume_path'] ?? '').toString().isNotEmpty;
    final passed = (hasName ? 1 : 0) + (hasResume ? 1 : 0);
    final score = ((passed / 2) * 100).round();

    return {
      'applied_count': List.from(apps).length,
      'profile_score': score,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchMyOffers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, status, created_at')
        .eq('user_id', userId)
        .inFilter('status', ['offer_sent', 'hired']);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _professionalDrawer(),
      body: Stack(
        children: [
          AnimatedBackgroundWrapper(
            child: IndexedStack(index: _idx, children: [
              _scoutTab(),
              _prepTab(),
              _trustTab(),
              _networkTab(),
              _growthTab(),
            ]),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.menu, color: AppColors.primary),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Scout"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_alt), label: "AI Prep"),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: "Trust ID"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Network"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: "Growth"),
        ],
      ),
    );
  }

  Widget _professionalDrawer() => Drawer(
        backgroundColor: Colors.white,
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E40AF)]),
            ),
            accountName: const Text("Candidate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            accountEmail: const Row(children: [
              Text("Elite Identity Verified", style: TextStyle(color: Colors.white70, fontSize: 10)),
              SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.white, size: 12)
            ]),
            currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF1E40AF))),
          ),
          ListTile(
            leading: const Icon(Icons.person_pin, color: Color(0xFF2563EB), size: 22),
            title: const Text("Update Profile", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (c) => const EliteProfileHub()));
            },
          ),
          _drawerNavTile(Icons.folder_special_outlined, "Career Portfolio", const Color(0xFF16A34A), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => const EliteCertificatesScreen()));
          }),
          _drawerNavTile(Icons.inventory_2_outlined, "Resume Vault", const Color(0xFF0F766E), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (c) => const ResumeVaultScreen()));
          }),
          const Divider(),
          AnimatedBuilder(
            animation: ThemeController.instance,
            builder: (context, _) => SwitchListTile(
              secondary: Icon(
                ThemeController.instance.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF1E40AF),
              ),
              title: const Text("Dark Mode", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
              value: ThemeController.instance.isDarkMode,
              onChanged: (v) => ThemeController.instance.setDarkMode(v),
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            title: const Text("Logout", style: TextStyle(color: Colors.black87, fontSize: 13)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          SizedBox(height: AppSpacing.lg),
        ]),
      );
  Widget _drawerNavTile(IconData i, String t, Color c, {VoidCallback? onTap}) => ListTile(
      leading: Icon(i, color: c, size: 22),
      title: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
      onTap: onTap);
  // --- TAB 1 SCOUT (PREMIUM) ---
  Widget _scoutTab() {
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
          final company = (job['company'] ?? '').toString().toLowerCase();
          return title.contains(searchLower) || company.contains(searchLower);
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
                    entry.value['title'] ?? 'N/A',
                    entry.value['company'] ?? 'N/A',
                    entry.value['mode'] ?? 'Hybrid',
                    entry.value['description'] ?? '',
                    _jobAccentColors[entry.key % _jobAccentColors.length])),
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
                            ))
                        .toList(),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EliteProfileHub())),
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
              hintText: "Search MNCs, Roles...",
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none)));

  Widget _filterHub() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _filterChip("Locations", ["Hyderabad", "Chennai", "Bengaluru", "Kolkata", "Delhi", "Pune", "Gurgaon"]),
        SizedBox(width: AppSpacing.sm),
        _filterChip("Work Mode", ["Hybrid", "Remote", "On-site"])
      ]));

  Widget _filterChip(String label, List<String> options) => ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 11)),
      onPressed: () => _showFilterSheet(label, options),
      avatar: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
      backgroundColor: Colors.white);
  void _showFilterSheet(String title, List<String> options) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
              const Divider(),
              Wrap(
                spacing: AppSpacing.sm,
                children: options
                    .map((o) => Chip(
                          label: Text(o, style: const TextStyle(color: Colors.black87)),
                          backgroundColor: const Color(0xFFF1F5F9),
                        ))
                    .toList(),
              )
            ])));
  }

  Widget _jobCard(String t, String c, String mode, String d, Color accent) {
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
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]),
                    borderRadius: AppBorderRadius.small),
                child: Icon(Icons.business_rounded, color: accent, size: 24)),
            SizedBox(width: AppSpacing.md),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: AppTypography.titleMedium),
              Text(c, style: AppTypography.bodySmallBold.copyWith(color: accent)),
            ])),
            _badge(mode, accent),
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

  // --- TAB 2 AI PREP HUB ---
  Widget _prepTab() => ListView(padding: EdgeInsets.fromLTRB(AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg), children: [
        Text("Interview Prep", style: AppTypography.headlineLarge.copyWith(color: AppColors.primary)),
        Text("These tools are in development — nothing here reflects real analysis yet.",
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        SizedBox(height: AppSpacing.xl),
        _premiumFeatureCard("Resume Quality / ATS Score", Icons.analytics_outlined,
            "Real scoring based on your uploaded resume content.", Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ResumeScoreScreen()))),
        _comingSoonCard("MNC Interview Question Banks", Icons.menu_book_outlined,
            "Curated question sets per company, tied to your applications.", AppColors.info),
        _premiumFeatureCard("Pitch Analysis", Icons.mic_outlined,
            "Speak your pitch and get real pacing and filler-word feedback.", AppColors.error,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PitchAnalysisScreen()))),
        _comingSoonCard("AI Interview Simulation", Icons.psychology_outlined,
            "Live mock interview rounds with real feedback.", Colors.purple),
      ]);

  Widget _premiumFeatureCard(String title, IconData icon, String desc, Color color, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.md),
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorderRadius.medium,
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppBorderRadius.small),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                    SizedBox(height: AppSpacing.xs),
                    Text(desc, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      );

  Widget _comingSoonCard(String title, IconData icon, String desc, Color color) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: AppBorderRadius.small),
              child: Icon(icon, color: color.withValues(alpha: 0.6), size: 22),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodySmallBold.copyWith(color: AppColors.textMuted)),
                  SizedBox(height: AppSpacing.xs),
                  Text(desc, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: AppBorderRadius.small),
              child: Text("SOON", style: AppTypography.captionBold.copyWith(color: AppColors.textMuted)),
            ),
          ],
        ),
      );

  // --- TAB 3: TRUST ID ---
  Widget _trustTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMyTrustData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final profile = snapshot.data ?? {};
        final hasName = (profile['full_name'] ?? '').toString().isNotEmpty;
        final hasResume = (profile['resume_path'] ?? '').toString().isNotEmpty;
        final checks = [
          {'label': 'Profile Name Set', 'passed': hasName},
          {'label': 'Resume Uploaded', 'passed': hasResume},
        ];
        final passedCount = checks.where((c) => c['passed'] == true).length;
        final score = ((passedCount / checks.length) * 100).round();

        return ListView(padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg), children: [
          _profileCompletenessCard(score),
          SizedBox(height: AppSpacing.xl),
          ...checks.map((c) => _verificationNode(
                c['label'] as String,
                c['passed'] == true ? 'Verified' : 'Not completed yet',
                c['passed'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                AppColors.info,
                c['passed'] as bool,
              )),
          SizedBox(height: AppSpacing.md),
          if (!hasResume)
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EliteProfileHub())),
              child: const Text("UPLOAD RESUME TO COMPLETE PROFILE"),
            ),
        ]);
      },
    );
  }

  Widget _profileCompletenessCard(int score) {
    final scoreColor = score == 100 ? AppColors.success : (score >= 50 ? AppColors.warning : AppColors.error);
    return Container(
      height: 200,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.primaryCard,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("PROFILE COMPLETENESS", style: AppTypography.sectionHeader.copyWith(color: Colors.white70)),
          Icon(Icons.verified_user, color: scoreColor, size: 24),
        ]),
        const Spacer(),
        Text("$score% COMPLETE",
            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 26)),
        Text(AppData.name.isEmpty ? "Candidate" : AppData.name,
            style: AppTypography.bodyMediumBold.copyWith(color: Colors.cyanAccent)),
      ]),
    );
  }

  Widget _verificationNode(String t, String s, IconData i, Color c, bool done) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.card(),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: c.withValues(alpha: 0.1), child: Icon(i, color: c, size: 18)),
          SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: AppTypography.bodyMediumBold),
            Text(s, style: AppTypography.caption.copyWith(color: AppColors.textMuted))
          ])),
          Icon(done ? Icons.verified : Icons.pending_outlined, color: done ? AppColors.success : AppColors.warning, size: 20),
        ]),
      );

  // --- TAB 4 NETWORK (PREMIUM) ---
  Widget _networkTab() {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait([_fetchTopRecruiters(), _fetchLeaderboard()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
        }
        final recruiters = snapshot.data?[0] ?? [];
        final leaderboard = snapshot.data?[1] ?? [];

        return ListView(padding: EdgeInsets.fromLTRB(AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg), children: [
          Row(children: [
            Icon(Icons.hub_outlined, color: AppColors.primary, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text("Talent Ecosystem", style: AppTypography.headlineLarge.copyWith(color: AppColors.primary)),
          ]),
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
                        onTap: () => setState(() => _isShowingLeaderboard = false),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                                gradient: !_isShowingLeaderboard ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]) : null,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: !_isShowingLeaderboard
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                    : null),
                            child: Center(
                                child: Text("MNC RECRUITERS",
                                    style: AppTypography.captionBold.copyWith(
                                        color: !_isShowingLeaderboard ? AppColors.textLight : AppColors.textMuted)))))),
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _isShowingLeaderboard = true),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                                gradient: _isShowingLeaderboard ? LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]) : null,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: _isShowingLeaderboard
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                    : null),
                            child: Center(
                                child: Text("GLOBAL LEADERBOARD",
                                    style: AppTypography.captionBold.copyWith(
                                        color: _isShowingLeaderboard ? AppColors.textLight : AppColors.textMuted)))))),
              ])),
          SizedBox(height: AppSpacing.xl),
          if (!_isShowingLeaderboard) ...[
            if (recruiters.isEmpty)
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text("No recruiters found yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))))
            else
              ...recruiters.asMap().entries.map((e) => _referralRecruiterCard(
                  e.value['full_name'] ?? 'Recruiter', "Recruiter", _jobAccentColors[e.key % _jobAccentColors.length])),
          ] else ...[
            if (leaderboard.isEmpty)
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text("No shortlisted candidates yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))))
            else
              ...leaderboard.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final row = entry.value;
                final colors = [AppColors.accentAmber, Colors.blueGrey, Colors.brown, AppColors.info, Colors.teal];
                return _leaderboardRank(
                    rank, row['name'], "Shortlisted Candidate", row['count'], colors[entry.key % colors.length]);
              }),
          ]
        ]);
      },
    );
  }

  Widget _referralRecruiterCard(String n, String r, Color c) => Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: c.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: c.withValues(alpha: 0.12),
            child: Text(n.isNotEmpty ? n[0] : '?', style: AppTypography.bodyMediumBold.copyWith(color: c))),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n, style: AppTypography.bodyMediumBold),
            Text(r, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        ),
        TextButton(
            style: TextButton.styleFrom(backgroundColor: c.withValues(alpha: 0.1)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Elite Referral Request Sent to $n successful"),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text("REFER ME", style: AppTypography.captionBold.copyWith(color: c)))
      ]));

  Widget _leaderboardRank(int r, String n, String t, int s, Color c) => Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: c,
            child: Text("#$r", style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textLight))),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n, style: AppTypography.bodyMediumBold),
            Text(t, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: AppDecorations.pill(c),
          child: Text("$s shortlisted", style: AppTypography.captionBold.copyWith(color: c)),
        ),
      ]));

  // --- TAB 5: GROWTH (PREMIUM) ---
  Widget _growthTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMyOffers(),
      builder: (context, snapshot) {
        final offers = snapshot.data ?? [];

        return ListView(padding: EdgeInsets.fromLTRB(AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg), children: [
          Row(children: [
            Icon(Icons.trending_up, color: AppColors.primary, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text("Career Growth", style: AppTypography.headlineLarge.copyWith(color: AppColors.primary)),
          ]),
          Text("Real tools, plus your offer tracking below", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          SizedBox(height: AppSpacing.xl),
          _premiumFeatureCard("Market Value Estimator", Icons.trending_up,
              "Real salary benchmarking from live job postings.", AppColors.success,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketValueEstimatorScreen()))),
          _premiumFeatureCard("AI Skill-Gap Analytics", Icons.auto_awesome_mosaic,
              "See real gaps between your skills and target roles.", AppColors.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SkillGapScreen()))),
          _comingSoonCard("Offer Negotiator", Icons.handshake,
              "AI-assisted analysis of offer terms and negotiation tips.", Colors.teal),
          _comingSoonCard("Portfolio Architect", Icons.architecture,
              "Guided project building tied to your target roles.", Colors.indigo),
          _premiumFeatureCard("Elite Certificates", Icons.workspace_premium,
              "Upload and manage your real, verifiable credentials.", AppColors.accentAmber,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EliteCertificatesScreen()))),
          SizedBox(height: AppSpacing.xxl),
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.card_membership, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text("MY OFFERS", style: AppTypography.sectionHeader),
                ]),
                SizedBox(height: AppSpacing.md),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (offers.isEmpty)
                  Text("No offers yet, keep applying.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
                else
                  ...offers.map((o) => _myOfferTile(o['job_title'] ?? 'N/A', o['company_name'] ?? 'N/A', o['status'] == 'hired', o['created_at']?.toString().split('T').first ?? 'Unknown')),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ]);
      },
    );
  }

  void _showOfferDetail(String role, String company, bool isHired, String appliedOn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Offer Details", style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Role", role),
            _detailRow("Company", company),
            _detailRow("Status", isHired ? "Hired" : "Offer Sent"),
            _detailRow("Applied On", appliedOn),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label: ", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            Text(value, style: AppTypography.bodySmallBold),
          ],
        ),
      );

  Widget _myOfferTile(String role, String company, bool isHired, String appliedOn) {
    final c = isHired ? AppColors.success : AppColors.info;
    return GestureDetector(
      onTap: () => _showOfferDetail(role, company, isHired, appliedOn),
      child: Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: c.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: AppBorderRadius.small),
            child: Icon(isHired ? Icons.check_circle : Icons.hourglass_bottom, color: c, size: 22),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                SizedBox(height: AppSpacing.xs),
                Text(isHired ? "Hired at $company" : "Offer sent by $company",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: c),
        ],
      ),
      ),
    );
  }
}

// --- ELITE PROFILE HUB ---
class EliteProfileHub extends StatefulWidget {
  const EliteProfileHub({super.key});
  @override
  State<EliteProfileHub> createState() => _EliteProfileHubState();
}

class _EliteProfileHubState extends State<EliteProfileHub> {
  bool _isUploading = false;
  String? _resumeFileName;
  String? _resumePath;

  @override
  void initState() {
    super.initState();
    _loadResumeStatus();
  }

  Future<void> _loadResumeStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('resume_path')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null && data['resume_path'] != null) {
        setState(() {
          _resumePath = data['resume_path'];
          _resumeFileName = _resumePath!.split('/').last;
        });
      }
    } catch (e) {
      debugPrint('Error loading resume status: $e');
    }
  }

  Future<void> _pickAndUploadResume() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final storagePath = '$userId/$fileName';

    setState(() => _isUploading = true);

    try {
      await Supabase.instance.client.storage
          .from('resumes')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('profiles').update({
        'resume_path': storagePath,
        'resume_uploaded_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        setState(() {
          _resumePath = storagePath;
          _resumeFileName = fileName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resume uploaded successfully!"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Update Profile", style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          _buildActiveStatus(),
          SizedBox(height: AppSpacing.xl),
          _sectionHeader("BASIC DETAILS"),
          _naukriCard(
              "Basic Details",
              Icons.person_outline,
              "Work Status, City, Mobile, Email, Availability",
              AppColors.info,
              () => _showUpdateLogic("Basic Details", [
                    "Work Status",
                    "Current City",
                    "Current Area",
                    "Mobile Number",
                    "Email ID",
                    "Availability to join"
                  ])),
          _sectionHeader("RESOURCES"),
          _naukriCard(
              "Export ATS Resume (PDF)",
              Icons.picture_as_pdf_outlined,
              "Generate & share corporate ATS resume",
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CandidateProfileHub()),
                );
              }),
          _naukriCard(
              "Resume",
              Icons.description_outlined,
              _isUploading ? "Uploading..." : (_resumeFileName ?? "No resume uploaded yet"),
              AppColors.success,
              _isUploading ? () {} : _pickAndUploadResume),
          _naukriCard("Video Profile", Icons.videocam_outlined, "AI Simulation Pitch", Colors.purple,
              () => _showUpdateLogic("Video Profile", ["Record AI Pitch", "Upload Video"])),
          _sectionHeader("PROFESSIONAL SUMMARY"),
          _naukriCard("Profile Summary", Icons.history_edu, "Professional developer overview", AppColors.warning,
              () => _showUpdateLogic("Summary", ["Professional Summary"])),
          _naukriCard("Key Skills", Icons.bolt, "Flutter, Dart, Firebase, SOLID", Colors.deepOrange,
              () => _showUpdateLogic("Key Skills", ["Add Skills", "Delete Skills"])),
          _sectionHeader("EXPERIENCE & ACADEMICS"),
          _naukriCard("Employment", Icons.business_center_outlined, "Senior Dev @ Tech Hub", Colors.indigo,
              () => _showUpdateLogic("Employment", ["Company Name", "Designation", "Joining Date"])),
          _naukriCard("Projects", Icons.account_tree_outlined, "Fintech App, E-com Engine", Colors.teal,
              () => _showUpdateLogic("Projects", ["Project Title", "Role", "Description"])),
          _naukriCard("IT Skills", Icons.terminal, "Git, Docker, Bloc, CI/CD, JIRA", Colors.blueGrey,
              () => _showUpdateLogic("IT Skills", ["Software Skills"])),
          _naukriCard("Education", Icons.school_outlined, "B.Tech Computer Science", Colors.brown,
              () => _showUpdateLogic("Education", ["University", "Year of Passing"])),
          _naukriCard("Accomplishments", Icons.emoji_events_outlined, "Certificates & Awards", AppColors.accentAmber,
              () => _showUpdateLogic("Accomplishments", ["Awards", "Online Certifications"])),
          _sectionHeader("PERSONAL & CAREER"),
          _naukriCard(
              "Personal Details",
              Icons.face,
              "DOB, Gender, Home Address",
              AppColors.textMuted,
              () => _showUpdateLogic("Personal Details", ["Date of Birth", "Permanent Address"])),
          _naukriCard(
              "Diversity & Inclusion",
              Icons.diversity_3_outlined,
              "Workplace Preferences",
              Colors.pink,
              () => _showUpdateLogic("Diversity", ["Gender Pref", "Specially Abled Status"])),
          _naukriSection("Languages", Icons.translate, "English, Hindi, Telugu", Colors.cyan),
          _naukriSection("Career Preferences", Icons.star_border, "Remote, Bangalore, 30LPA+", AppColors.info),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildActiveStatus() => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Row(children: [
          const CircleAvatar(
              radius: 25, backgroundColor: Colors.greenAccent, child: Icon(Icons.bolt, color: Colors.white)),
          SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Actively searching jobs", style: AppTypography.bodyMediumBold.copyWith(color: AppColors.success)),
            Text("Profile visibility: High", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ])),
          Switch(value: true, onChanged: (v) {}, activeColor: AppColors.success),
        ]),
      );

  Widget _sectionHeader(String t) => Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(t, style: AppTypography.sectionHeader));

  Widget _naukriCard(String title, IconData icon, String sub, Color color, VoidCallback onTap) => Card(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        elevation: 0.2,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        child: ListTile(
          onTap: onTap,
          leading: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppBorderRadius.small),
              child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: AppTypography.bodyMediumBold),
          subtitle: Text(sub, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          trailing: Icon(Icons.add_circle_outline, color: AppColors.info, size: 20),
        ),
      );

  Widget _naukriSection(String title, IconData icon, String subtitle, Color color) =>
      _naukriCard(title, icon, subtitle, color, () => _showUpdateLogic(title, ["Update $title"]));

  void _showUpdateLogic(String title, List<String> fields) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Update $title", style: AppTypography.titleMedium),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
          ]),
          const Divider(),
          SizedBox(height: AppSpacing.sm),
          ...fields
              .map((f) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextField(
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                            labelText: f,
                            labelStyle: TextStyle(color: AppColors.textMuted),
                            border: OutlineInputBorder(borderRadius: AppBorderRadius.small),
                            filled: true,
                            fillColor: AppColors.surfaceVariant)),
                  ))
              .toList(),
          SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SAVE CHANGES"),
          ),
        ]),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogo({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size, size), painter: AshWheelPainter(wheelColor: finalColor)),
        SizedBox(width: AppSpacing.sm),
        Text("Hylo", style: GoogleFonts.lobster(color: finalColor, fontSize: size)),
      ],
    );
  }
}
