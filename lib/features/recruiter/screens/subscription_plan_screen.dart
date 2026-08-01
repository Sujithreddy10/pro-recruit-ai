import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class _PlanTier {
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

  const _PlanTier({
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
}

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  late Future<String> _currentTierFuture;
  bool _isUpdating = false;

  static const _tiers = [
    _PlanTier(
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
    _PlanTier(
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
    _PlanTier(
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

  @override
  void initState() {
    super.initState();
    _currentTierFuture = _fetchCurrentTier();
  }

  Future<String> _fetchCurrentTier() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 'free';
    final data = await Supabase.instance.client
        .from('profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();
    return data?['subscription_tier'] as String? ?? 'free';
  }

  Future<void> _selectPlan(_PlanTier tier) async {
    if (tier.id == 'enterprise') {
      final uri = Uri.parse(
        'mailto:sales@hylo.app?subject=${Uri.encodeComponent("Enterprise Plan Inquiry")}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open mail app. Email sales@hylo.app directly.")),
        );
      }
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isUpdating = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'subscription_tier': tier.id})
          .eq('id', userId);
      setState(() => _currentTierFuture = Future.value(tier.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're now on the ${tier.title} plan"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update plan: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Subscription Plan", style: AppTypography.titleMedium.copyWith(color: const Color(0xFFB45309))),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Color(0xFFB45309)),
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _currentTierFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final currentTier = snapshot.data ?? 'free';

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 32),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("YOUR PLAN", style: AppTypography.sectionHeader.copyWith(color: Colors.white60, letterSpacing: 2)),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            _tiers.firstWhere((t) => t.id == currentTier, orElse: () => _tiers.first).title,
                            style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              ..._tiers.map((tier) => _planCard(tier, isCurrent: tier.id == currentTier)),
              SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  "Prices shown for illustration. Enterprise pricing is custom.",
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _planCard(_PlanTier tier, {required bool isCurrent}) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(color: tier.gradient.last.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: tier.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(tier.icon, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.title, style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 20)),
                          Text(tier.tagline, style: AppTypography.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorderRadius.small),
                        child: Text("CURRENT", style: AppTypography.captionBold.copyWith(color: tier.gradient.last)),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tier.price, style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 32)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(tier.period, style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                ...tier.features.map((f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(f, style: AppTypography.bodySmall.copyWith(color: Colors.white))),
                        ],
                      ),
                    )),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isUpdating || isCurrent) ? null : () => _selectPlan(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: tier.gradient.last,
                      disabledBackgroundColor: Colors.white.withValues(alpha: isCurrent ? 0.9 : 0.4),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                    ),
                    child: Text(
                      isCurrent ? "Current Plan" : tier.ctaLabel,
                      style: AppTypography.bodyMediumBold.copyWith(color: isCurrent ? tier.gradient.last : tier.gradient.last),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
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
