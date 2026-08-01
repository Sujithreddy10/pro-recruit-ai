import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late Future<List<Map<String, dynamic>>> _teamFuture;
  final TextEditingController _inviteEmailCtrl = TextEditingController();
  bool _isInviting = false;
  String? _busyId;

  static const _accentColors = [
    Color(0xFF2563EB),
    Colors.deepPurple,
    Colors.teal,
    Color(0xFFEA580C),
  ];

  @override
  void initState() {
    super.initState();
    _teamFuture = _fetchTeam();
  }

  void _refresh() {
    setState(() => _teamFuture = _fetchTeam());
  }

  Future<List<Map<String, dynamic>>> _fetchTeam() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, is_team_admin')
        .eq('user_role', 'recruiter')
        .order('full_name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _inviteTeammate() async {
    final email = _inviteEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email address")),
      );
      return;
    }

    setState(() => _isInviting = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'team-invite',
        body: {'action': 'invite', 'email': email},
      );

      if (response.status != 200) {
        final err = (response.data is Map) ? response.data['error'] : 'Server error (${response.status})';
        throw err.toString();
      }

      _inviteEmailCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invite sent to $email"), backgroundColor: AppColors.success),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to invite: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _confirmRemove(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Remove ${member['full_name'] ?? 'this teammate'}?", style: AppTypography.titleMedium),
        content: Text(
          "They will lose access to the recruiter console immediately. This can't be undone.",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Remove", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyId = member['id']);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'team-invite',
        body: {'action': 'remove', 'userId': member['id']},
      );

      if (response.status != 200) {
        final err = (response.data is Map) ? response.data['error'] : 'Server error (${response.status})';
        throw err.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Removed ${member['full_name'] ?? 'teammate'}"), backgroundColor: AppColors.success),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _toggleAdmin(Map<String, dynamic> member) async {
    final makeAdmin = member['is_team_admin'] != true;
    setState(() => _busyId = member['id']);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'team-invite',
        body: {'action': 'set_admin', 'userId': member['id'], 'isAdmin': makeAdmin},
      );

      if (response.status != 200) {
        final err = (response.data is Map) ? response.data['error'] : 'Server error (${response.status})';
        throw err.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(makeAdmin ? "Made ${member['full_name']} an admin" : "Removed admin from ${member['full_name']}"),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update admin status: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Invite Teammate", style: AppTypography.titleMedium),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _inviteEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "teammate@company.com",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: BorderSide(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.small,
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isInviting
                      ? null
                      : () async {
                          setSheetState(() {});
                          await _inviteTeammate();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                  ),
                  child: _isInviting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text("Send Invite", style: AppTypography.bodyMediumBold.copyWith(color: Colors.white)),
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
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Team Management", style: AppTypography.titleMedium.copyWith(color: const Color(0xFF2563EB))),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Color(0xFF2563EB)),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final team = snapshot.data ?? [];
          final me = team.where((m) => m['id'] == myId).toList();
          final isAdmin = me.isNotEmpty && me.first['is_team_admin'] == true;

          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, isAdmin ? 100 : AppSpacing.lg),
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppBorderRadius.large,
                      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: Colors.white, size: 32),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("YOUR RECRUITING TEAM", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 1.5)),
                              SizedBox(height: AppSpacing.xs),
                              Text("${team.length} ${team.length == 1 ? 'member' : 'members'}", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 22)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAdmin) ...[
                    SizedBox(height: AppSpacing.md),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: AppBorderRadius.medium,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            "Only team admins can invite or remove members. Ask an admin to promote you if you need access.",
                            style: AppTypography.caption.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  SizedBox(height: AppSpacing.xl),
                  if (team.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Text("No teammates yet.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                      ),
                    )
                  else
                    ...team.asMap().entries.map((entry) {
                      final member = entry.value;
                      final color = _accentColors[entry.key % _accentColors.length];
                      final name = member['full_name'] ?? 'Recruiter';
                      final isMe = member['id'] == myId;
                      final memberIsAdmin = member['is_team_admin'] == true;
                      final isBusy = _busyId == member['id'];

                      return Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppBorderRadius.medium,
                          border: Border.all(color: color.withValues(alpha: 0.15)),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color.withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: AppTypography.bodyMediumBold.copyWith(color: color),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: AppSpacing.xs,
                                        children: [
                                          Text(name, style: AppTypography.bodyMediumBold),
                                          if (isMe)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                                              decoration: AppDecorations.pill(color),
                                              child: Text("YOU", style: AppTypography.captionBold.copyWith(color: color, fontSize: 9)),
                                            ),
                                          if (memberIsAdmin)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                                              decoration: AppDecorations.pill(AppColors.accentAmber),
                                              child: Text("ADMIN", style: AppTypography.captionBold.copyWith(color: AppColors.accentAmber, fontSize: 9)),
                                            ),
                                        ],
                                      ),
                                      Text("Recruiter", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                if (isAdmin && !isMe)
                                  isBusy
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : IconButton(
                                          icon: Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                                          onPressed: () => _confirmRemove(member),
                                          tooltip: "Remove from team",
                                        ),
                              ],
                            ),
                            if (isAdmin && !isMe) ...[
                              SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isBusy ? null : () => _toggleAdmin(member),
                                  child: Text(
                                    memberIsAdmin ? "Revoke Admin" : "Make Admin",
                                    style: AppTypography.captionBold.copyWith(color: color),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
              if (isAdmin)
                Positioned(
                  bottom: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: FloatingActionButton.extended(
                    onPressed: _showInviteDialog,
                    backgroundColor: const Color(0xFF2563EB),
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                    label: Text("Invite", style: AppTypography.bodyMediumBold.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
