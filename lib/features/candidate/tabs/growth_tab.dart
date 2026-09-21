import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/candidate/screens/market_value_estimator_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/skill_gap_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/offer_negotiator_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/portfolio_architect_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/elite_certificates_screen.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_growth_card.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_offer_card.dart';
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
          .select()
          .eq('user_id', userId)
          .or('status.eq.offer_sent,status.eq.hired')
          .order('created_at', ascending: false);

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

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.primary, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    "Career Growth",
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Text(
                "Real tools, plus your offer tracking below",
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: AppSpacing.xl),
              CandidateGrowthCard(
                title: "Market Value Estimator",
                icon: Icons.trending_up,
                description: "Real salary benchmarking from live job postings.",
                accentColor: AppColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const MarketValueEstimatorScreen()),
                ),
              ),
              CandidateGrowthCard(
                title: "AI Skill-Gap Analytics",
                icon: Icons.auto_awesome_mosaic,
                description: "See real gaps between your skills and target roles.",
                accentColor: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SkillGapScreen()),
                ),
              ),
              CandidateGrowthCard(
                title: "Offer Negotiator",
                icon: Icons.handshake,
                description: "AI-assisted analysis of offer terms and negotiation tips.",
                accentColor: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const OfferNegotiatorScreen()),
                ),
              ),
              CandidateGrowthCard(
                title: "Portfolio Architect",
                icon: Icons.architecture,
                description: "Guided project building tied to your target roles.",
                accentColor: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const PortfolioArchitectScreen()),
                ),
              ),
              CandidateGrowthCard(
                title: "Elite Certificates",
                icon: Icons.workspace_premium,
                description: "Upload and manage your real, verifiable credentials.",
                accentColor: AppColors.accentAmber,
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
                      Text(
                        "No offers yet, keep applying.",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      )
                    else
                      ...offers.map((o) => CandidateOfferCard(
                            role: o['job_title'] ?? 'N/A',
                            company: o['company_name'] ?? 'N/A',
                            isHired: o['status'] == 'hired',
                            appliedOn: o['created_at']?.toString().split('T').first ?? 'Unknown',
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}
