import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateOfferCard extends StatefulWidget {
  final String applicationId;
  final String role;
  final String company;
  final String status;
  final String ctc;
  final String appliedOn;
  final VoidCallback? onStatusChanged;

  const CandidateOfferCard({
    super.key,
    required this.applicationId,
    required this.role,
    required this.company,
    required this.status,
    required this.ctc,
    required this.appliedOn,
    this.onStatusChanged,
  });

  @override
  State<CandidateOfferCard> createState() => _CandidateOfferCardState();
}

class _CandidateOfferCardState extends State<CandidateOfferCard> {
  bool _isUpdating = false;

  bool get isHired => widget.status.toLowerCase() == 'hired';
  bool get isRejected => widget.status.toLowerCase() == 'rejected';

  Future<void> _updateOfferStatus(String newStatus, BuildContext ctx) async {
    setState(() => _isUpdating = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(ctx);

    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus})
          .eq('id', widget.applicationId);

      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'hired'
                ? "Congratulations! You accepted the offer from ${widget.company}!"
                : "Offer declined.",
          ),
          backgroundColor: newStatus == 'hired' ? AppColors.success : AppColors.textMuted,
        ),
      );
      widget.onStatusChanged?.call();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showOfferDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.work_outline, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.role, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(widget.company, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: AppBorderRadius.small,
                  border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow("Compensation / CTC", widget.ctc.isNotEmpty ? widget.ctc : "As per discussion", isHighlight: true),
                    const Divider(height: 16, color: Colors.white10),
                    _buildRow("Current Status", isHired ? "Offer Accepted (Hired)" : (isRejected ? "Declined" : "Offer Extended")),
                    const Divider(height: 16, color: Colors.white10),
                    _buildRow("Applied Date", widget.appliedOn),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              if (!isHired && !isRejected) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUpdating ? null : () => _updateOfferStatus('rejected', ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Decline", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : () => _updateOfferStatus('hired', ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isUpdating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Accept Offer 🎉", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHired ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isHired ? "Offer Accepted ✓" : "Close", style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        Text(
          value,
          style: AppTypography.bodySmallBold.copyWith(
            color: isHighlight ? AppColors.success : null,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color badgeColor = isHired
        ? AppColors.success
        : (isRejected ? AppColors.error : AppColors.primary);

    return GestureDetector(
      onTap: () => _showOfferDetail(context),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: AppBorderRadius.small,
              ),
              child: Icon(
                isHired ? Icons.verified : (isRejected ? Icons.cancel_outlined : Icons.card_giftcard),
                color: badgeColor,
                size: 22,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.role,
                          style: AppTypography.bodyMediumBold.copyWith(
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.ctc.isNotEmpty)
                        Text(
                          widget.ctc,
                          style: AppTypography.captionBold.copyWith(color: AppColors.success),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    isHired
                        ? "Hired at ${widget.company}"
                        : (isRejected ? "Offer declined" : "Offer received from ${widget.company}"),
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: badgeColor),
          ],
        ),
      ),
    );
  }
}
