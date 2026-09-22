import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class TeamManagementHeader extends StatelessWidget {
  final int memberCount;

  const TeamManagementHeader({super.key, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.white, size: 32),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "YOUR RECRUITING TEAM",
                  style: AppTypography.sectionHeader.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "$memberCount ${memberCount == 1 ? 'member' : 'members'}",
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeamNonAdminNotice extends StatelessWidget {
  const TeamNonAdminNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Only team admins can invite or remove members. Ask an admin to promote you if you need access.",
              style: AppTypography.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  final String name;
  final bool isMe;
  final bool memberIsAdmin;
  final bool isAdmin;
  final bool isBusy;
  final Color accentColor;
  final VoidCallback onRemove;
  final VoidCallback onToggleAdmin;

  const TeamMemberCard({
    super.key,
    required this.name,
    required this.isMe,
    required this.memberIsAdmin,
    required this.isAdmin,
    required this.isBusy,
    required this.accentColor,
    required this.onRemove,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.bodyMediumBold.copyWith(color: accentColor),
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
                            decoration: AppDecorations.pill(accentColor),
                            child: Text(
                              "YOU",
                              style: AppTypography.captionBold.copyWith(
                                color: accentColor,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        if (memberIsAdmin)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                            decoration: AppDecorations.pill(AppColors.accentAmber),
                            child: Text(
                              "ADMIN",
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.accentAmber,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      "Recruiter",
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isAdmin && !isMe)
                isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                        onPressed: onRemove,
                        tooltip: "Remove from team",
                      ),
            ],
          ),
          if (isAdmin && !isMe) ...[
            SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy ? null : onToggleAdmin,
                child: Text(
                  memberIsAdmin ? "Revoke Admin" : "Make Admin",
                  style: AppTypography.captionBold.copyWith(color: accentColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TeamInviteSheet extends StatelessWidget {
  final TextEditingController controller;
  final bool isInviting;
  final VoidCallback onSend;

  const TeamInviteSheet({
    super.key,
    required this.controller,
    required this.isInviting,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Invite Teammate", style: AppTypography.titleMedium),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
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
              onPressed: isInviting ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
              ),
              child: isInviting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text("Send Invite", style: AppTypography.bodyMediumBold.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
