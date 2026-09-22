import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ResumeVaultHeader extends StatelessWidget {
  final int count;
  final int max;

  const ResumeVaultHeader({super.key, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded, color: Colors.tealAccent, size: 32),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("YOUR VAULT", style: AppTypography.sectionHeader.copyWith(color: Colors.white60, letterSpacing: 2)),
                SizedBox(height: AppSpacing.xs),
                Text("$count / $max resumes", style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight)),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "Tailor a resume per role and switch your primary anytime",
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

class ResumeVaultEmptyView extends StatelessWidget {
  const ResumeVaultEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: AppSpacing.sm),
          Text(
            "No resumes yet. Upload your first one below.",
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class ResumeVaultCard extends StatelessWidget {
  final Map<String, dynamic> resume;
  final VoidCallback onSetPrimary;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ResumeVaultCard({
    super.key,
    required this.resume,
    required this.onSetPrimary,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = resume['is_primary'] == true;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.large,
        border: Border.all(color: isPrimary ? const Color(0xFF0F766E) : AppColors.border, width: isPrimary ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              borderRadius: AppBorderRadius.small,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F766E)),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        resume['label'] ?? resume['file_name'] ?? 'Resume',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("PRIMARY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  resume['file_name'] ?? '',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: (action) {
              if (action == 'primary') onSetPrimary();
              if (action == 'rename') onRename();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (c) => [
              if (!isPrimary) const PopupMenuItem(value: 'primary', child: Text("Set as Primary")),
              const PopupMenuItem(value: 'rename', child: Text("Rename")),
              const PopupMenuItem(value: 'delete', child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }
}

class ResumeVaultUploadButton extends StatelessWidget {
  final bool atLimit;
  final bool isUploading;
  final VoidCallback? onPressed;

  const ResumeVaultUploadButton({
    super.key,
    required this.atLimit,
    required this.isUploading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isUploading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: atLimit ? AppColors.textMuted : const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
        ),
        icon: isUploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(atLimit ? Icons.lock_outline : Icons.upload_file_rounded),
        label: Text(atLimit ? "Maximum Resumes Reached (3/3)" : "Upload Resume (PDF)"),
      ),
    );
  }
}

class RenameResumeDialog extends StatelessWidget {
  final TextEditingController controller;

  const RenameResumeDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rename Resume"),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: "e.g. Software Engineer Resume"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class DeleteResumeDialog extends StatelessWidget {
  final String label;

  const DeleteResumeDialog({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Resume?"),
      content: Text("\"$label\" will be permanently removed."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    );
  }
}

class ResumeLimitDialog extends StatelessWidget {
  const ResumeLimitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Resume Slot Limit Reached"),
      content: const Text(
        "You can store up to 3 resumes at a time. Delete one you no longer need to upload a new version.",
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
          onPressed: () => Navigator.pop(context),
          child: const Text("Got it"),
        ),
      ],
    );
  }
}
