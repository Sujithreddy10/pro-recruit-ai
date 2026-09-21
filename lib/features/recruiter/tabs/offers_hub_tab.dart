import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/recruiter_offer_cards.dart';
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

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              RecruiterOfferHeader(
                pendingCount: pending.length,
                securedCount: secured.length,
              ),
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
                ...pending.map((o) => RecruiterPendingOfferCard(
                      name: o['profiles']?['full_name'] ?? 'Unknown Candidate',
                      role: o['job_title'] ?? 'N/A',
                      onMarkAccepted: () => _markOfferAccepted(o['id']),
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
                ...secured.map((o) => RecruiterSecuredOfferTile(
                      name: o['profiles']?['full_name'] ?? 'Unknown Candidate',
                      role: o['job_title'] ?? 'N/A',
                    )),
            ],
          ),
        );
      },
    );
  }
}
