import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class PlanTier {
  final String id;
  final String title;
  final String price;
  final String period;
  final String tagline;
  final List<String> features;
  final List<Color> gradient;
  final IconData icon;
  final String? badge;
  final String ctaLabel;

  const PlanTier({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.tagline,
    required this.features,
    required this.gradient,
    required this.icon,
    required this.ctaLabel,
    this.badge,
  });

  static const List<PlanTier> defaults = [
    PlanTier(
      id: 'free',
      title: 'Free',
      price: '\$0',
      period: '/forever',
      tagline: 'Get started with the essentials',
      icon: Icons.spa_outlined,
      gradient: [Color(0xFF334155), Color(0xFF1E293B)],
      ctaLabel: 'Switch to Free',
      features: [
        '20 AI actions / month',
        '1 active job posting',
        'Basic candidate pipeline',
        'Community support',
      ],
    ),
    PlanTier(
      id: 'pro',
      title: 'Pro',
      price: '\$49',
      period: '/month',
      tagline: 'For recruiters hiring at scale',
      icon: Icons.workspace_premium_rounded,
      gradient: [Color(0xFFB45309), Color(0xFFF59E0B)],
      badge: 'MOST POPULAR',
      ctaLabel: 'Switch to Pro',
      features: [
        '200 AI actions / month',
        'Unlimited job postings',
        'Talent Match + AI Assistant',
        'Collab Hub team notes',
        'Priority email support',
      ],
    ),
    PlanTier(
      id: 'enterprise',
      title: 'Enterprise',
      price: 'Custom',
      period: '',
      tagline: 'For hiring teams and agencies',
      icon: Icons.diamond_outlined,
      gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      ctaLabel: 'Contact Sales',
      features: [
        'Unlimited AI actions',
        'Full Team Management',
        'Dedicated account manager',
        'Custom integrations & SSO',
        'SLA-backed support',
      ],
    ),
  ];
}

class SubscriptionPlanHeader extends StatelessWidget {
  final String activeTierTitle;

  const SubscriptionPlanHeader({super.key, required this.activeTierTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 32),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "YOUR PLAN",
                  style: AppTypography.sectionHeader.copyWith(color: Colors.white60, letterSpacing: 2),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  activeTierTitle,
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanTierCard extends StatelessWidget {
  final PlanTier tier;
  final bool isCurrent;
  final bool isUpdating;
  final VoidCallback onSelect;

  const PlanTierCard({
    super.key,
    required this.tier,
    required this.isCurrent,
    required this.isUpdating,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(
            color: tier.gradient.last.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tier.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorderRadius.large,
              border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tier.icon, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.title,
                            style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 20),
                          ),
                          Text(
                            tier.tagline,
                            style: AppTypography.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorderRadius.small),
                        child: Text(
                          "CURRENT",
                          style: AppTypography.captionBold.copyWith(color: tier.gradient.last),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tier.price,
                      style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 32),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tier.period,
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                ...tier.features.map(
                  (f) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(f, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isUpdating || isCurrent) ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: tier.gradient.last,
                      disabledBackgroundColor: Colors.white.withValues(alpha: isCurrent ? 0.9 : 0.4),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                    ),
                    child: Text(
                      isCurrent ? "Current Plan" : tier.ctaLabel,
                      style: AppTypography.bodyMediumBold.copyWith(color: tier.gradient.last),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (tier.badge != null)
            Positioned(
              top: -12,
              right: AppSpacing.lg,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  tier.badge!,
                  style: AppTypography.captionBold.copyWith(color: tier.gradient.last, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
