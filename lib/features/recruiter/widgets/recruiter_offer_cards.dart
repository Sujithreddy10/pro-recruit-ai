import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class RecruiterOfferHeader extends StatelessWidget {
  final int pendingCount;
  final int securedCount;

  const RecruiterOfferHeader({
    super.key,
    required this.pendingCount,
    required this.securedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = pendingCount + securedCount;
    final rate = total == 0 ? 0 : ((securedCount / total) * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    "CONVERSION RATE: $rate%",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  "$securedCount Hired Candidates",
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "$pendingCount offers currently awaiting candidate decision",
                  style: AppTypography.caption.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.verified_user_rounded, color: AppColors.success, size: 28),
          ),
        ],
      ),
    );
  }
}

class RecruiterPendingOfferCard extends StatelessWidget {
  final String name;
  final String role;
  final String? date;
  final String? compensation;
  final bool isLoading;
  final VoidCallback onMarkAccepted;
  final VoidCallback onCancelOffer;

  const RecruiterPendingOfferCard({
    super.key,
    required this.name,
    required this.role,
    this.date,
    this.compensation,
    this.isLoading = false,
    required this.onMarkAccepted,
    required this.onCancelOffer,
  });

  String _formatCompensation(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return raw;
    if (clean.contains('₹') || clean.contains(r'$') || clean.toLowerCase().contains('lpa') || clean.toLowerCase().contains('k')) {
      return clean;
    }
    final numVal = int.tryParse(clean.replaceAll(',', ''));
    if (numVal != null) {
      if (numVal >= 100000) {
        final s = numVal.toString();
        final lastThree = s.substring(s.length - 3);
        final otherDigits = s.substring(0, s.length - 3);
        final buffer = StringBuffer();
        for (int i = 0; i < otherDigits.length; i++) {
          final posFromRight = otherDigits.length - i;
          buffer.write(otherDigits[i]);
          if (posFromRight > 1 && posFromRight % 2 == 1) {
            buffer.write(',');
          }
        }
        final formattedOther = buffer.toString();
        return '₹${formattedOther.isNotEmpty ? "$formattedOther," : ""}$lastThree / yr';
      } else {
        return '₹$numVal / yr';
      }
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = Colors.amber.shade700;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
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
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
                      style: AppTypography.bodyMediumBold.copyWith(
                        color: isDark ? AppColors.textLight : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role + (date != null ? " • Sent $date" : ""),
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: warningColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  "OFFER SENT",
                  style: TextStyle(
                    color: warningColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (compensation != null && compensation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    _formatCompensation(compensation!),
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isLoading ? null : onCancelOffer,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                ),
                child: const Text("Revoke", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isLoading ? null : onMarkAccepted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 14, color: Colors.white),
                label: const Text(
                  "Mark Hired",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecruiterSecuredOfferTile extends StatelessWidget {
  final String name;
  final String role;
  final String? date;

  const RecruiterSecuredOfferTile({
    super.key,
    required this.name,
    required this.role,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: AppBorderRadius.small,
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMediumBold.copyWith(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role + (date != null ? " • Hired $date" : ""),
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              "HIRED",
              style: TextStyle(
                color: AppColors.success,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
