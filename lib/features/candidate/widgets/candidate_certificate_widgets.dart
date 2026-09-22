import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CertificateHeaderCard extends StatelessWidget {
  final int count;

  const CertificateHeaderCard({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF78350F), AppColors.accentAmber]),
        borderRadius: AppBorderRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR CREDENTIALS", style: AppTypography.sectionHeader.copyWith(color: Colors.amber.shade100)),
          SizedBox(height: AppSpacing.xs),
          Text("$count Certificates Uploaded",
              style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 18)),
          Text("Real, verifiable credentials you've earned",
              style: AppTypography.caption.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class CertificateEmptyView extends StatelessWidget {
  const CertificateEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.md),
            Text(
              "No certificates uploaded yet. Tap \"Add Certificate\" to add your first one.",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class CertificateItemCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const CertificateItemCard({
    super.key,
    required this.cert,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.accentAmber.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium, color: AppColors.accentAmber, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert['title'] ?? 'N/A', style: AppTypography.bodyMediumBold),
                Text(cert['issuing_org'] ?? 'N/A', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                if (cert['date_earned'] != null)
                  Text("Earned: ${cert['date_earned']}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: AppColors.info, size: 20),
            onPressed: onView,
            tooltip: "View",
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: onDelete,
            tooltip: "Delete",
          ),
        ],
      ),
    );
  }
}

class DeleteCertificateDialog extends StatelessWidget {
  final String title;

  const DeleteCertificateDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
      title: Text("Delete Certificate?", style: AppTypography.titleMedium),
      content: Text("This will permanently remove \"$title\".", style: AppTypography.bodySmall),
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

class AddCertificateFormData {
  final String title;
  final String issuingOrg;
  final DateTime? dateEarned;
  final PlatformFile file;

  AddCertificateFormData({
    required this.title,
    required this.issuingOrg,
    required this.dateEarned,
    required this.file,
  });
}

class AddCertificateBottomSheet extends StatefulWidget {
  const AddCertificateBottomSheet({super.key});

  @override
  State<AddCertificateBottomSheet> createState() => _AddCertificateBottomSheetState();
}

class _AddCertificateBottomSheetState extends State<AddCertificateBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  DateTime? _selectedDate;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _orgCtrl.text.trim().isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title, organization, and file are all required.")),
      );
      return;
    }

    Navigator.pop(
      context,
      AddCertificateFormData(
        title: _titleCtrl.text.trim(),
        issuingOrg: _orgCtrl.text.trim(),
        dateEarned: _selectedDate,
        file: _pickedFile!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add Certificate", style: AppTypography.titleMedium),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            SizedBox(height: AppSpacing.sm),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Certificate Title")),
            SizedBox(height: AppSpacing.md),
            TextField(controller: _orgCtrl, decoration: const InputDecoration(labelText: "Issuing Organization")),
            SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Date Earned"),
                child: Text(_selectedDate == null
                    ? "Select date"
                    : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  withData: true,
                );
                if (result != null) setState(() => _pickedFile = result.files.single);
              },
              icon: const Icon(Icons.upload_file),
              label: Text(_pickedFile == null ? "Choose File (PDF/Image)" : _pickedFile!.name),
            ),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text("UPLOAD CERTIFICATE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
