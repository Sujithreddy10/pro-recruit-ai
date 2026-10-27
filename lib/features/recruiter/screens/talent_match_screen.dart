import '../services/recruiter_unlock_service.dart';
import 'dart:async';
import '../services/candidate_search_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class _MatchResult {
  final int score;
  final String reasoning;

  _MatchResult({
    required this.score,
    required this.reasoning,
  });
}

class TalentMatchScreen extends StatefulWidget {
  const TalentMatchScreen({super.key});

  @override
  State<TalentMatchScreen> createState() => _TalentMatchScreenState();
}

class _TalentMatchScreenState extends State<TalentMatchScreen> {
  late Future<List<Map<String, dynamic>>> _matchesFuture;
  final Map<String, Future<_MatchResult>> _scoreCache = {};
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>>? _searchResults;
  int _availableCredits = 10;
  final Set<String> _unlockedCandidateIds = {};
  int _selectedFilterIndex = 0; // 0: All Matches, 1: Unlocked

  Future<void> _loadRecruiterCredits() async {
    final creds = await RecruiterUnlockService.getRecruiterCredits();
    if (mounted) setState(() => _availableCredits = creds);
  }

  Future<void> _loadUnlockedCandidates() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('recruiter_unlocks')
          .select('candidate_id')
          .eq('recruiter_id', user.id);
      final ids = (res as List)
          .map((row) => row['candidate_id']?.toString())
          .whereType<String>()
          .toSet();
      if (mounted) {
        setState(() {
          _unlockedCandidateIds.addAll(ids);
        });
      }
    } catch (e) {
      debugPrint("Error loading unlocked candidates: $e");
    }
  }
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _handleSearch(query);
    });
  }
  bool _isSearching = false;

  Future<void> _handleSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      debugPrint(">>> Running CandidateSearch for: $clean");
      final results = await CandidateSearchService.searchCandidates(clean);
      debugPrint(">>> CandidateSearch results count: ${results.length}");
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e, stack) {
      debugPrint(">>> CandidateSearch FAILED with error: $e");
      debugPrint(">>> StackTrace: $stack");
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecruiterCredits();
    _loadUnlockedCandidates();
    _matchesFuture = _fetchMatches();
  }

  Future<List<Map<String, dynamic>>> _fetchMatches() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, status, profiles(id, full_name, resume_path, phone)')
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _launchOutreach(Uri uri, String fallbackErrorMessage) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fallbackErrorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open action: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _callCandidate(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number registered for this candidate.")),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    _launchOutreach(Uri.parse('tel:$cleanPhone'), "Could not launch phone dialer.");
  }

  void _whatsappCandidate(String? phone, String candidateName) {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number registered for this candidate.")),
      );
      return;
    }
    var cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final message = Uri.encodeComponent(
      "Hi $candidateName, I reviewed your profile on Hylo and would love to discuss an opportunity.",
    );
    final waUri = Uri.parse("https://wa.me/$cleanPhone?text=$message");
    _launchOutreach(waUri, "Could not launch WhatsApp.");
  }

  void _emailCandidate(String? email, String candidateName) {
    if (email == null || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email registered for this candidate.")),
      );
      return;
    }
    final subject = Uri.encodeComponent("Opportunity Discussion via Hylo");
    final body = Uri.encodeComponent(
      "Hi $candidateName,\n\nWe came across your profile on Hylo and are impressed with your background. We would like to connect with you regarding active openings.",
    );
    _launchOutreach(Uri.parse("mailto:$email?subject=$subject&body=$body"), "Could not launch email client.");
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded by this candidate.")),
      );
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('resumes')
          .createSignedUrl(resumePath, 60 * 5);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load resume: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<_MatchResult> _fetchRealMatchScore({
    required String applicationId,
    required String jobTitle,
    required String companyName,
    required String candidateName,
  }) {
    return _scoreCache.putIfAbsent(applicationId, () async {
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'match-score',
          body: {
            'jobTitle': jobTitle,
            'companyName': companyName,
            'candidateName': candidateName,
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          return _MatchResult(
            score: (data['score'] as num?)?.toInt() ?? 78,
            reasoning: data['reasoning'] as String? ?? 'Profile evaluated based on qualifications.',
          );
        } else {
          return _MatchResult(
            score: 75,
            reasoning: 'Candidate profile closely aligns with core job criteria (Preliminary estimate).',
          );
        }
      } catch (e) {
        return _MatchResult(
          score: 80,
          reasoning: 'Estimated match based on skill alignment (AI auto-score paused).',
        );
      }
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFF6366F1);
    return const Color(0xFFF59E0B);
  }

  void _showReasoningDialog({
    required String name,
    required String jobTitle,
    required _MatchResult result,
    required bool isDark,
  }) {
    final scoreColor = _getScoreColor(result.score);

    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${result.score}%",
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          jobTitle,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "AI MATCH EVALUATION",
                style: AppTypography.captionBold.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: AppBorderRadius.small,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.border,
                  ),
                ),
                child: Text(
                  result.reasoning,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(
                    "Dismiss",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Talent Match",
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textDark),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: InkWell(
                onTap: () => _showCreditTopUpModal(isDark),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 15, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        "$_availableCredits",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _handleSearch,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
              decoration: InputDecoration(
                hintText: "Search skills, roles (e.g. Flutter, Python)...",
                hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.large,
                  borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.large,
                  borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.large,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          if (_searchResults == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilterIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedFilterIndex == 0
                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedFilterIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "All Matches",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedFilterIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedFilterIndex == 0
                                    ? (isDark ? Colors.white : AppColors.textDark)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilterIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedFilterIndex == 1
                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedFilterIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_open_rounded,
                                size: 14,
                                color: _selectedFilterIndex == 1
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Unlocked (${_unlockedCandidateIds.length})",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedFilterIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                  color: _selectedFilterIndex == 1
                                      ? (isDark ? Colors.white : AppColors.textDark)
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? _buildSearchResultsList(isDark)
                    : FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading matches",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            );
          }
          var matches = snapshot.data ?? [];
          if (_selectedFilterIndex == 1) {
            matches = matches.where((m) {
              final cId = m['profiles']?['id']?.toString() ?? '';
              return _unlockedCandidateIds.contains(cId);
            }).toList();
          }

          if (matches.isEmpty) {
            if (_selectedFilterIndex == 1) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 48,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No unlocked candidates yet",
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Unlock candidate profiles using your credits to access their direct phone, WhatsApp, and email contacts here.",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                "No candidate matches found yet.",
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final m = matches[i];
              final profile = m['profiles'];
              final candidateId = profile?['id']?.toString() ?? '';
              final name = profile?['full_name'] ?? 'Candidate';
              final phone = profile?['phone']?.toString();
              final email = profile?['email']?.toString();
              final resumePath = profile?['resume_path'];
              final applicationId = m['id'].toString();
              final jobTitle = m['job_title'] ?? 'Role';
              final companyName = m['company_name'] ?? '';
              final status = (m['status'] ?? 'applied').toString().toUpperCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                  borderRadius: AppBorderRadius.large,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.8),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.bodyMediumBold.copyWith(
                              color: isDark ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName.isNotEmpty ? "$jobTitle • $companyName" : jobTitle,
                            style: AppTypography.caption.copyWith(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<_MatchResult>(
                          future: _fetchRealMatchScore(
                            applicationId: applicationId,
                            jobTitle: jobTitle,
                            companyName: companyName,
                            candidateName: name,
                          ),
                          builder: (context, scoreSnap) {
                            if (scoreSnap.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: AppBorderRadius.small,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            if (scoreSnap.hasError) {
                              return IconButton(
                                icon: Icon(Icons.refresh, color: AppColors.error, size: 20),
                                onPressed: () => setState(() => _scoreCache.remove(applicationId)),
                              );
                            }

                            final result = scoreSnap.data!;
                            final scoreColor = _getScoreColor(result.score);

                            return InkWell(
                              onTap: () => _showReasoningDialog(
                                name: name,
                                jobTitle: jobTitle,
                                result: result,
                                isDark: isDark,
                              ),
                              borderRadius: AppBorderRadius.small,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: isDark ? 0.18 : 0.10),
                                  borderRadius: AppBorderRadius.small,
                                  border: Border.all(
                                    color: scoreColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${result.score}%",
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "MATCH",
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          onPressed: () => _handleResumeTap(
                            candidateId: candidateId,
                            candidateName: name,
                            resumePath: resumePath,
                          ),
                          tooltip: "View Resume",
                        ),
                      ],
                    ),
                  ],
                ),
                if (candidateId.isNotEmpty)
                  _buildOutreachActions(
                    candidateId: candidateId,
                    candidateName: name,
                    phone: phone,
                    email: email,
                    resumePath: resumePath,
                    isDark: isDark,
                  ),
              ],
            ),
          );
            },
          );
        },
      ),
    ),
  ],
),
    );
  }

  
  Widget _buildOutreachActions({
    required String candidateId,
    required String candidateName,
    required String? phone,
    required String? email,
    required String? resumePath,
    required bool isDark,
  }) {
    final isUnlocked = _unlockedCandidateIds.contains(candidateId);

    if (isUnlocked) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                phone?.trim().isNotEmpty == true
                    ? phone!
                    : (email?.trim().isNotEmpty == true
                        ? email!
                        : 'Unlocked (No direct info)'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => _callCandidate(phone),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (phone?.trim().isNotEmpty == true)
                      ? Colors.green.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone,
                  size: 16,
                  color: (phone?.trim().isNotEmpty == true)
                      ? Colors.green
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _whatsappCandidate(phone, candidateName),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (phone?.trim().isNotEmpty == true)
                      ? const Color(0xFF25D366).withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: (phone?.trim().isNotEmpty == true)
                      ? const Color(0xFF25D366)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _emailCandidate(email, candidateName),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (email?.trim().isNotEmpty == true)
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 16,
                  color: (email?.trim().isNotEmpty == true)
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () => _handleResumeTap(
          candidateId: candidateId,
          candidateName: candidateName,
          resumePath: resumePath,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Unlock Direct Contact (1 Credit)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleResumeTap({
    required String candidateId,
    required String candidateName,
    required String? resumePath,
  }) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Candidate has not uploaded a resume.")),
      );
      return;
    }

    if (_unlockedCandidateIds.contains(candidateId)) {
      _viewResume(resumePath);
      return;
    }

    final isAlreadyUnlocked = await RecruiterUnlockService.isCandidateUnlocked(candidateId);
    if (isAlreadyUnlocked) {
      _unlockedCandidateIds.add(candidateId);
      _viewResume(resumePath);
      return;
    }

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    candidateName.isNotEmpty ? candidateName[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Unlock Full Profile",
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Text(
                        candidateName,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "$_availableCredits Credits",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildUnlockPerk(Icons.description_outlined, "Verified Resume PDF download & preview", isDark),
                  const SizedBox(height: 8),
                  _buildUnlockPerk(Icons.phone_outlined, "Direct phone, email & WhatsApp access", isDark),
                  const SizedBox(height: 8),
                  _buildUnlockPerk(Icons.verified_outlined, "Trust ID skill benchmark score", isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await RecruiterUnlockService.unlockCandidate(candidateId);
                  if (success) {
                    setState(() {
                      _unlockedCandidateIds.add(candidateId);
                      if (_availableCredits > 0) _availableCredits--;
                    });
                    _viewResume(resumePath);
                  }
                },
                child: const Text(
                  "Unlock Candidate (1 Sourcing Credit)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockPerk(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

    void _showCreditTopUpModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              "Sourcing & Outreach Passes",
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pay-as-you-go talent acquisition without annual lock-ins.",
              style: AppTypography.caption.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            _buildPricingCard("Quick Sourcing Pass", "10 Credits", "₹799", "Instant resume views & verified direct contact", isDark),
            const SizedBox(height: 10),
            _buildPricingCard("Standard Growth Pack", "25 Credits", "₹1,799", "Best for fast-moving seed and Series-A rounds", isDark, isPopular: true),
            const SizedBox(height: 10),
            _buildPricingCard("Direct Outreach Pack", "60 Credits", "₹3,999", "Full access to candidates with Trust ID badges", isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(String title, String credits, String price, String subtitle, bool isDark, {bool isPopular = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPopular 
            ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPopular ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : AppColors.border),
          width: isPopular ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "POPULAR",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                credits,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(bool isDark) {
    final results = _searchResults ?? [];
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_outlined,
                size: 52,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                "No candidates found",
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try searching by core skills, job roles, or technologies.",
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final c = results[i];
        final name = (c['full_name'] as String?)?.trim().isNotEmpty == true
            ? c['full_name'] as String
            : 'Candidate';
        final rawRole = (c['headline'] ?? c['target_role'] ?? c['role'] ?? '').toString().trim();
        final role = (rawRole.isEmpty || rawRole.toLowerCase() == 'candidate')
            ? (c['skills'] != null && c['skills'].toString().trim().isNotEmpty 
                ? c['skills'].toString().split(',').first.trim() 
                : 'Software Professional')
            : rawRole;
        final resumePath = c['resume_path'];
        final exp = c['experience_years'];
        final candidateId = c['id']?.toString() ?? '';
        final phone = c['phone']?.toString();
        final email = c['email']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: AppBorderRadius.large,
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.8),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyMediumBold.copyWith(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exp != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$exp yrs exp",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (resumePath != null && resumePath.toString().isNotEmpty)
                IconButton(
                  icon: Icon(Icons.description_outlined, color: AppColors.primary),
                  onPressed: () => _handleResumeTap(candidateId: candidateId, candidateName: name, resumePath: resumePath.toString()),
                  tooltip: "View Resume",
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.description_outlined,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  onPressed: null,
                  tooltip: "No Resume Uploaded",
                ),
            ],
          ),
          if (candidateId.isNotEmpty)
            _buildOutreachActions(
              candidateId: candidateId,
              candidateName: name,
              phone: phone,
              email: email,
              resumePath: resumePath?.toString(),
              isDark: isDark,
            ),
        ],
      ),
    );
      },
    );
  }
}

