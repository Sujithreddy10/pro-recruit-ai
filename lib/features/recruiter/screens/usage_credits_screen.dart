import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/subscription_plan_screen.dart';

class UsageCreditsScreen extends StatefulWidget {
  const UsageCreditsScreen({super.key});

  @override
  State<UsageCreditsScreen> createState() => _UsageCreditsScreenState();
}

class _UsageCreditsScreenState extends State<UsageCreditsScreen> {
  late Future<Map<String, dynamic>> _usageFuture;

  static const _tierLimits = {'free': 20, 'pro': 200, 'enterprise': -1};
  static const _tierLabels = {'free': 'Free', 'pro': 'Pro', 'enterprise': 'Enterprise'};

  static const _featureMeta = {
    'intake-chat': {'label': 'Intake Agent', 'icon': Icons.support_agent, 'color': Colors.teal},
    'match-score': {'label': 'Talent Match', 'icon': Icons.psychology_outlined, 'color': Colors.deepPurple},
    'generate-draft': {'label': 'AI Assistant', 'icon': Icons.auto_fix_high, 'color': Colors.indigo},
    'skill-gap': {'label': 'Skill-Gap Analytics', 'icon': Icons.auto_awesome_mosaic, 'color': Colors.pinkAccent},
  };

  @override
  void initState() {
    super.initState();
    _usageFuture = _fetchUsageData();
  }

  Future<Map<String, dynamic>> _fetchUsageData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return {'tier': 'free', 'total': 0, 'byFeature': <String, int>{}};
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('subscription_tier')
        .eq('id', userId)
        .maybeSingle();
    final tier = profile?['subscription_tier'] as String? ?? 'free';

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final logs = await Supabase.instance.client
        .from('ai_usage_log')
        .select('feature')
        .eq('user_id', userId)
        .gte('created_at', startOfMonth.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(logs);
    final byFeature = <String, int>{};
    for (final r in rows) {
      final f = r['feature'] as String;
      byFeature[f] = (byFeature[f] ?? 0) + 1;
    }

    return {'tier': tier, 'total': rows.length, 'byFeature': byFeature};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Usage Credits", style: AppTypography.titleMedium.copyWith(color: const Color(0xFF16A34A))),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Color(0xFF16A34A)),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _usageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }

          final data = snapshot.data ?? {'tier': 'free', 'total': 0, 'byFeature': <String, int>{}};
          final tier = data['tier'] as String;
          final total = data['total'] as int;
          final byFeature = data['byFeature'] as Map<String, int>;
          final limit = _tierLimits[tier] ?? 20;
          final isUnlimited = limit < 0;
          final ratio = isUnlimited ? 0.0 : (limit == 0 ? 1.0 : (total / limit).clamp(0.0, 1.0));
          final nearLimit = !isUnlimited && ratio >= 0.7;

          final meterColor = isUnlimited
              ? Colors.tealAccent
              : ratio >= 0.9
                  ? AppColors.error
                  : ratio >= 0.7
                      ? AppColors.warning
                      : Colors.greenAccent;

          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.large,
                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("AI CREDITS THIS MONTH", style: AppTypography.sectionHeader.copyWith(color: Colors.white70, letterSpacing: 1.5)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: AppBorderRadius.small),
                          child: Text(_tierLabels[tier] ?? 'Free', style: AppTypography.captionBold.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("$total", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 40)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 6),
                          child: Text(
                            isUnlimited ? " / Unlimited" : " / $limit used",
                            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: AppBorderRadius.small,
                      child: LinearProgressIndicator(
                        value: isUnlimited ? 1.0 : ratio,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: meterColor,
                      ),
                    ),
                    if (nearLimit) ...[
                      SizedBox(height: AppSpacing.md),
                      Row(children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 16),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            "You're close to your monthly limit.",
                            style: AppTypography.caption.copyWith(color: Colors.amberAccent),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              if (tier != 'enterprise') ...[
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SubscriptionPlanScreen())),
                    icon: const Icon(Icons.upgrade, size: 18),
                    label: Text("Upgrade for more credits", style: AppTypography.bodyMediumBold),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                    ),
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
              Text("BREAKDOWN BY TOOL", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              ..._featureMeta.entries.map((entry) {
                final count = byFeature[entry.key] ?? 0;
                final meta = entry.value;
                final color = meta['color'] as Color;
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorderRadius.medium,
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(meta['icon'] as IconData, color: color, size: 20),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(meta['label'] as String, style: AppTypography.bodyMediumBold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: AppDecorations.pill(color),
                        child: Text("$count", style: AppTypography.captionBold.copyWith(color: color)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
