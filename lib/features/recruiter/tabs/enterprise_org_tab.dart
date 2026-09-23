import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_org_cards.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class EnterpriseOrgTab extends StatefulWidget {
  const EnterpriseOrgTab({super.key});

  @override
  State<EnterpriseOrgTab> createState() => _EnterpriseOrgTabState();
}

class _EnterpriseOrgTabState extends State<EnterpriseOrgTab>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _orgDataFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrgData();
  }

  void _loadOrgData() {
    _orgDataFuture = _fetchOrgData();
  }

  Future<Map<String, dynamic>> _fetchOrgData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // 1. Fetch counts
    final recruitersCount = await client
        .from('profiles')
        .select()
        .eq('user_role', 'recruiter')
        .count(CountOption.exact);

    final candidatesCount = await client
        .from('profiles')
        .select()
        .eq('user_role', 'candidate')
        .count(CountOption.exact);

    final jobsCount =
        await client.from('jobs').select().count(CountOption.exact);

    final applicationsCount =
        await client.from('applications').select().count(CountOption.exact);

    // 2. Fetch current profile
    Map<String, dynamic>? profile;
    if (user != null) {
      final res = await client
          .from('profiles')
          .select('full_name, company_name, email, role')
          .eq('id', user.id)
          .maybeSingle();
      profile = res;
    }

    // 3. Fetch recruiter team directory
    final team = await client
        .from('profiles')
        .select('id, full_name, email, role, user_role')
        .eq('user_role', 'recruiter')
        .limit(10);

    return {
      'recruiters': recruitersCount.count,
      'candidates': candidatesCount.count,
      'jobs': jobsCount.count,
      'applications': applicationsCount.count,
      'profile': profile,
      'team': team,
      'user_id': user?.id,
      'user_email': user?.email,
    };
  }

  void _showInviteMemberSheet() {
    final emailController = TextEditingController();
    String selectedRole = "Recruiter";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text("Invite Team Member", style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    "Send an enterprise workspace invite to your hiring team",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text("Work Email", style: AppTypography.captionBold),
                  SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "colleague@company.com",
                      prefixIcon: const Icon(Icons.mail_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: AppBorderRadius.small),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text("Workspace Permission", style: AppTypography.captionBold),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppBorderRadius.small,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: "Recruiter", child: Text("Recruiter (Pipeline & Offers)")),
                          DropdownMenuItem(value: "Hiring Manager", child: Text("Hiring Manager (Review only)")),
                          DropdownMenuItem(value: "Admin", child: Text("Workspace Admin (Full access)")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedRole = val);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (emailController.text.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Invite dispatched to ${emailController.text.trim()}!"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Send Invite", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sign Out?"),
        content: const Text("Are you sure you want to end your active recruiter session?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 16.0;

    return FutureBuilder<Map<String, dynamic>>(
      future: _orgDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final recruiters = (data['recruiters'] as int?) ?? 0;
        final candidates = (data['candidates'] as int?) ?? 0;
        final jobs = (data['jobs'] as int?) ?? 0;
        final applications = (data['applications'] as int?) ?? 0;

        final profile = data['profile'] as Map<String, dynamic>?;
        final team = (data['team'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final currentUserId = data['user_id'] as String?;
        final currentUserEmail = data['user_email'] as String? ?? "recruiter@workspace.internal";

        final companyName = profile?['company_name'] ?? "Hylo Enterprise";
        final recruiterName = profile?['full_name'] ?? "Lead Recruiter";

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadOrgData());
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset, AppSpacing.lg, 90),
            children: [
              RecruiterOrgProfileCard(
                companyName: companyName,
                recruiterName: recruiterName,
                recruiterEmail: currentUserEmail,
              ),
              SizedBox(height: AppSpacing.xl),
              Text("WORKSPACE METRICS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              RecruiterOrgStatGrid(
                recruiters: recruiters,
                candidates: candidates,
                jobs: jobs,
                applications: applications,
              ),
              SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("HIRING TEAM (${team.isEmpty ? 1 : team.length})", style: AppTypography.sectionHeader),
                  TextButton.icon(
                    onPressed: _showInviteMemberSheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Invite"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              if (team.isEmpty)
                RecruiterTeamMemberTile(
                  name: recruiterName,
                  role: "Workspace Admin",
                  email: currentUserEmail,
                  isCurrentUser: true,
                )
              else
                ...team.map((member) {
                  final isMe = member['id'] == currentUserId;
                  return RecruiterTeamMemberTile(
                    name: member['full_name'] ?? (isMe ? recruiterName : "Team Member"),
                    role: member['role'] ?? "Recruiter",
                    email: member['email'] ?? (isMe ? currentUserEmail : "recruiter@company.com"),
                    isCurrentUser: isMe,
                  );
                }),
              SizedBox(height: AppSpacing.xl),
              Text("ACCOUNT & SECURITY", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.medium,
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_none_outlined),
                      title: const Text("Push & Email Alerts"),
                      subtitle: const Text("Manage candidate and offer alerts"),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Alert preferences are up to date.")),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.sync_alt_outlined),
                      title: const Text("Calendar & ATS Integrations"),
                      subtitle: const Text("Connected to Supabase Cloud"),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: Icon(Icons.logout, color: AppColors.error),
                      title: Text("Sign Out", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      subtitle: const Text("End active recruiter session"),
                      onTap: _confirmSignOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
