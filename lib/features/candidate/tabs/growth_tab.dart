import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/screens/elite_certificates_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/market_value_estimator_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/offer_negotiator_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/portfolio_architect_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/skill_gap_screen.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class GrowthTab extends StatefulWidget {
  const GrowthTab({super.key});

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _offersFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchMyOffers();
  }

  Future<List<Map<String, dynamic>>> _fetchMyOffers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await Supabase.instance.client
          .from('applications')
          .select('id, job_title, company_name, status, created_at')
          .eq('user_id', userId)
          .inFilter('status', ['offer_sent', 'hired']);

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        final offers = snapshot.data ?? [];

        return ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 120, AppSpacing.lg, AppSpacing.lg),
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 24),
                SizedBox(width: AppSpacing.sm),
                Text("Career Growth",
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.primary)),
              ],
            ),
            Text("Real tools, plus your offer tracking below",
                style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.xl),
            _premiumFeatureCard(
              "Market Value Estimator",
              Icons.trending_up,
              "Real salary benchmarking from live job postings.",
              AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const MarketValueEstimatorScreen()),
              ),
            ),
            _premiumFeatureCard(
              "AI Skill-Gap Analytics",
              Icons.auto_awesome_mosaic,
              "See real gaps between your skills and target roles.",
              AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SkillGapScreen()),
              ),
            ),
            _premiumFeatureCard(
              "Offer Negotiator",
              Icons.handshake,
              "AI-assisted analysis of offer terms and negotiation tips.",
              Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const OfferNegotiatorScreen()),
              ),
            ),
            _premiumFeatureCard(
              "Portfolio Architect",
              Icons.architecture,
              "Guided project building tied to your target roles.",
              Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const PortfolioArchitectScreen()),
              ),
            ),
            _premiumFeatureCard(
              "Elite Certificates",
              Icons.workspace_premium,
              "Upload and manage your real, verifiable credentials.",
              AppColors.accentAmber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const EliteCertificatesScreen()),
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_membership, size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.xs),
                      Text("MY OFFERS", style: AppTypography.sectionHeader),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (offers.isEmpty)
                    Text("No offers yet, keep applying.",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
                  else
                    ...offers.map((o) => _myOfferTile(
                          o['job_title'] ?? 'N/A',
                          o['company_name'] ?? 'N/A',
                          o['status'] == 'hired',
                          o['created_at']?.toString().split('T').first ?? 'Unknown',
                        )),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _premiumFeatureCard(
    String title,
    IconData icon,
    String desc,
    Color color, {
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.md),
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorderRadius.medium,
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.small,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                    SizedBox(height: AppSpacing.xs),
                    Text(desc, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      );

  void _showOfferDetail(String role, String company, bool isHired, String appliedOn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Offer Details", style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Role", role),
            _detailRow("Company", company),
            _detailRow("Status", isHired ? "Hired" : "Offer Sent"),
            _detailRow("Applied On", appliedOn),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$label: ", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            Text(value, style: AppTypography.bodySmallBold),
          ],
        ),
      );

  Widget _myOfferTile(String role, String company, bool isHired, String appliedOn) {
    final c = isHired ? AppColors.success : AppColors.info;
    return GestureDetector(
      onTap: () => _showOfferDetail(role, company, isHired, appliedOn),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: c.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration:
                  BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: AppBorderRadius.small),
              child: Icon(isHired ? Icons.check_circle : Icons.hourglass_bottom, color: c, size: 22),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role,
                      style: AppTypography.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: AppSpacing.xs),
                  Text(isHired ? "Hired at $company" : "Offer sent by $company",
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: c),
          ],
        ),
      ),
    );
  }
}
