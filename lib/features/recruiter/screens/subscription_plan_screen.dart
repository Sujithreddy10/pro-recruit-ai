import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/subscription_plan_widgets.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  late Future<String> _currentTierFuture;
  bool _isUpdating = false;

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

  Future<void> _selectPlan(PlanTier tier) async {
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
          final currentPlan = PlanTier.defaults.firstWhere(
            (t) => t.id == currentTier,
            orElse: () => PlanTier.defaults.first,
          );

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              SubscriptionPlanHeader(activeTierTitle: currentPlan.title),
              SizedBox(height: AppSpacing.xl),
              ...PlanTier.defaults.map(
                (tier) => PlanTierCard(
                  tier: tier,
                  isCurrent: tier.id == currentTier,
                  isUpdating: _isUpdating,
                  onSelect: () => _selectPlan(tier),
                ),
              ),
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
}
