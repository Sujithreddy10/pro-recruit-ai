import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import '../widgets/recruiter_header_stats.dart';

class HiringSwipeTab extends StatefulWidget {
  const HiringSwipeTab({super.key});

  @override
  State<HiringSwipeTab> createState() => _HiringSwipeTabState();
}

class _HiringSwipeTabState extends State<HiringSwipeTab> with AutomaticKeepAliveClientMixin {
  String _selectedRole = "All Roles";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Future<List<Map<String, dynamic>>> _applicantsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applicantsFuture = _fetchApplicants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchApplicants() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('*, profiles(full_name, resume_path)')
        .eq('status', 'applied')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No resume uploaded by this candidate.")),
        );
      }
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('resumes')
          .createSignedUrl(resumePath, 60 * 5);

      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open resume URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load resume: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleDecision(bool approved, int applicationId) async {
    final newStatus = approved ? 'shortlisted' : 'rejected';
    try {
      await Supabase.instance.client
          .from('applications')
          .update({
            'status': newStatus,
            'status_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? "Candidate moved to Shortlist" : "Candidate Archived"),
          backgroundColor: approved ? AppColors.success : AppColors.error,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _applicantsFuture = _fetchApplicants();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textDark,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: "Search candidate or role...",
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRolePills(List<Map<String, dynamic>> allApplicants) {
    final Map<String, int> counts = {"All Roles": allApplicants.length};
    for (final app in allApplicants) {
      final role = (app['job_title'] ?? 'General').toString().trim();
      if (role.isNotEmpty) {
        counts[role] = (counts[role] ?? 0) + 1;
      }
    }

    final roles = counts.keys.toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = _selectedRole == role;
          final count = counts[role] ?? 0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_selectedRole != role) {
                  setState(() => _selectedRole = role);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicantTile(Map<String, dynamic> app, bool isDark) {
    final name = app['profiles']?['full_name'] ?? 'Candidate #${app['id']}';
    final role = app['job_title'] ?? 'Role not specified';
    final date = (app['created_at'] ?? '').toString().split('T').first;
    final resumePath = app['profiles']?['resume_path'] as String?;
    final matchScore = app['match_score'] ?? app['ai_score'] ?? 88;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "$matchScore% Match",
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  "Applied: $date",
                  style: AppTypography.caption.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (resumePath != null && resumePath.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _viewResume(resumePath),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.redAccent),
                    label: const Text(
                      "Resume",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDecision(false, app['id']),
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text("Archive"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDecision(true, app['id']),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Shortlist"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 8.0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
          );
        }

        final allApplicants = snapshot.data ?? [];
        final visibleApplicants = allApplicants.where((a) {
          final matchesRole = _selectedRole == "All Roles" || (a['job_title'] ?? 'General') == _selectedRole;
          if (!matchesRole) return false;
          if (_searchQuery.isEmpty) return true;
          final name = (a['profiles']?['full_name'] ?? '').toString().toLowerCase();
          final job = (a['job_title'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || job.contains(_searchQuery);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _applicantsFuture = _fetchApplicants();
            });
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topInset,
              AppSpacing.lg,
              100.0,
            ),
            children: [
              const RecruiterHeaderStats(),
              SizedBox(height: AppSpacing.md),
              _buildSearchBar(isDark),
              SizedBox(height: AppSpacing.md),
              _buildRolePills(allApplicants),
              SizedBox(height: AppSpacing.lg),
              if (visibleApplicants.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          "No pending applicants.",
                          style: AppTypography.bodyMediumBold.copyWith(
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          "All candidates for this role have been reviewed.",
                          style: AppTypography.caption.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...visibleApplicants.map((app) => _buildApplicantTile(app, isDark)),
            ],
          ),
        );
      },
    );
  }
}
