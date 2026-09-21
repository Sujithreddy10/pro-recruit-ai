import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class OffersHubTab extends StatefulWidget {
  const OffersHubTab({super.key});

  @override
  State<OffersHubTab> createState() => _OffersHubTabState();
}

class _OffersHubTabState extends State<OffersHubTab> with AutomaticKeepAliveClientMixin {
  late Future<List<List<Map<String, dynamic>>>> _offersFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    _offersFuture = Future.wait([_fetchPendingOffers(), _fetchSecuredOffers()]);
  }

  Future<List<Map<String, dynamic>>> _fetchPendingOffers() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, created_at, profiles(full_name)')
        .eq('status', 'offer_sent')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchSecuredOffers() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, created_at, profiles(full_name)')
        .eq('status', 'hired')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _markOfferAccepted(int applicationId) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': 'hired', 'status_updated_at': DateTime.now().toIso8601String()})
          .eq('id', applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Marked as Hired"), backgroundColor: AppColors.success),
        );
        setState(() {
          _loadOffers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _offerHeader(int pendingCount, int securedCount) {
    final total = pendingCount + securedCount;
    final rate = total == 0 ? 0 : ((securedCount / total) * 100).round();
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF059669)]),
        borderRadius: AppBorderRadius.large,
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "OFFER ACCEPTANCE: $rate%",
                style: AppTypography.sectionHeader.copyWith(color: Colors.greenAccent),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                "$securedCount Offers Secured",
                style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "$pendingCount pending",
                style: AppTypography.caption.copyWith(color: Colors.white60),
              ),
            ]),
          ),
          SizedBox(width: AppSpacing.md),
          Icon(Icons.verified_user, color: AppColors.textLight, size: 40),
        ],
      ),
    );
  }

  Widget _offerTrackingCard(String name, String role, int applicationId) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning.withValues(alpha: 0.06), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 18),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(name, style: AppTypography.bodyMediumBold, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: AppDecorations.pill(AppColors.warning),
              child: Text("PENDING", style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
            ),
          ]),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ),
          SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF064E3B), AppColors.success]),
                borderRadius: AppBorderRadius.small,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _markOfferAccepted(applicationId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textLight,
                ),
                child: Text(
                  "MARK ACCEPTED",
                  style: AppTypography.captionBold.copyWith(color: AppColors.textLight),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _securedOfferTile(String name, String role) => Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.success.withValues(alpha: 0.08), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: AppTypography.bodyMediumBold),
              Text(role, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ]),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(AppColors.success),
            child: Text("HIRED", style: AppTypography.captionBold.copyWith(color: AppColors.success)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium),
          );
        }
        final pending = snapshot.data?[0] ?? [];
        final secured = snapshot.data?[1] ?? [];

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
          children: [
            _offerHeader(pending.length, secured.length),
            SizedBox(height: AppSpacing.xl),
            Text("PENDING OFFERS", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            if (pending.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  "No pending offers yet.",
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              )
            else
              ...pending.map((o) => _offerTrackingCard(
                    o['profiles']?['full_name'] ?? 'Unknown Candidate',
                    o['job_title'] ?? 'N/A',
                    o['id'],
                  )),
            SizedBox(height: AppSpacing.xxl),
            Text("RECENTLY SECURED", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.md),
            if (secured.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  "No offers secured yet.",
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              )
            else
              ...secured.map((o) => _securedOfferTile(
                    o['profiles']?['full_name'] ?? 'Unknown Candidate',
                    o['job_title'] ?? 'N/A',
                  )),
          ],
        );
      },
    );
  }
}
