import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/team_management_widgets.dart';

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
    final currentStatus = member['is_team_admin'] == true;
    final newStatus = !currentStatus;
    final name = member['full_name'] ?? 'teammate';

    setState(() => _busyId = member['id']);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'team-invite',
        body: {
          'action': 'set-admin',
          'userId': member['id'],
          'isAdmin': newStatus,
        },
      );

      if (response.status != 200) {
        final err = (response.data is Map) ? response.data['error'] : 'Server error (${response.status})';
        throw err.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? "$name promoted to Admin" : "Admin rights revoked for $name"),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => TeamInviteSheet(
          controller: _inviteEmailCtrl,
          isInviting: _isInviting,
          onSend: () async {
            setSheetState(() {});
            await _inviteTeammate();
          },
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
                  TeamManagementHeader(memberCount: team.length),
                  if (!isAdmin) ...[
                    SizedBox(height: AppSpacing.md),
                    const TeamNonAdminNotice(),
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

                      return TeamMemberCard(
                        name: name,
                        isMe: isMe,
                        memberIsAdmin: memberIsAdmin,
                        isAdmin: isAdmin,
                        isBusy: isBusy,
                        accentColor: color,
                        onRemove: () => _confirmRemove(member),
                        onToggleAdmin: () => _toggleAdmin(member),
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
