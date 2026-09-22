import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ProfileSectionHeaderRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final String label;

  const ProfileSectionHeaderRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onAdd,
    this.label = "Add",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.sectionHeader.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: Icon(label == "Edit" ? Icons.edit_outlined : Icons.add_circle_outline, size: 16),
          label: Text(label),
        ),
      ],
    );
  }
}

class ProfileEmptyCard extends StatelessWidget {
  final String message;

  const ProfileEmptyCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMediumBold),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class ProfileHeroHeader extends StatelessWidget {
  final String name;
  final String identityStatus;
  final String? pendingVerificationSessionId;
  final int skillsCount;
  final int projectsCount;
  final VoidCallback? onVerifyTap;

  const ProfileHeroHeader({
    super.key,
    required this.name,
    required this.identityStatus,
    required this.pendingVerificationSessionId,
    required this.skillsCount,
    required this.projectsCount,
    this.onVerifyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = identityStatus == 'verified';

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            Colors.indigo.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 28),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onVerifyTap,
                  child: Row(
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified
                            : (pendingVerificationSessionId != null ? Icons.refresh : Icons.gpp_maybe_outlined),
                        color: isVerified ? Colors.greenAccent : Colors.white60,
                        size: 16,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        isVerified
                            ? "HYLO VERIFIED"
                            : (pendingVerificationSessionId != null ? "CHECK STATUS" : "VERIFY IDENTITY"),
                        style: AppTypography.sectionHeader.copyWith(
                          color: isVerified ? Colors.greenAccent : Colors.white60,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  name,
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 20),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "$skillsCount skills · $projectsCount projects",
                  style: AppTypography.caption.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onEdit;

  const ProfileProjectCard({
    super.key,
    required this.project,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tags = (project['tech_tags'] as String? ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade50,
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_special_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  project['title'] ?? '',
                  style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(project['description'] ?? '', style: AppTypography.bodySmall),
          if (tags.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags
                  .map((t) => Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t,
                          style: AppTypography.captionBold.copyWith(color: AppColors.primary),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileResumeCard extends StatelessWidget {
  final bool isUploading;
  final String? resumePath;
  final VoidCallback onTap;

  const ProfileResumeCard({
    super.key,
    required this.isUploading,
    required this.resumePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.2,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      child: ListTile(
        onTap: isUploading ? null : onTap,
        leading: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppBorderRadius.small,
          ),
          child: Icon(Icons.description_outlined, color: AppColors.success, size: 20),
        ),
        title: const Text("Resume"),
        subtitle: Text(
          isUploading
              ? "Uploading..."
              : (resumePath != null ? resumePath!.split('/').last : "No resume uploaded yet"),
        ),
        trailing: const Icon(Icons.upload_file, size: 20),
      ),
    );
  }
}

class ProfileExportPdfButton extends StatelessWidget {
  final VoidCallback onExport;

  const ProfileExportPdfButton({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: AppBorderRadius.medium,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onExport,
        icon: const Icon(Icons.download_rounded),
        label: const Text("Export Corporate ATS Resume (PDF)"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 55),
        ),
      ),
    );
  }
}
