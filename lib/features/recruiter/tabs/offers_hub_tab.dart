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
  int? _busyApplicationId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    _offersFuture = Future.wait([
      _fetchOffersByStatus('offer_sent'),
      _fetchOffersByStatus('hired'),
    ]);
  }

  Future<List<Map<String, dynamic>>> _fetchOffersByStatus(String status) async {
    try {
      final data = await Supabase.instance.client
          .from('applications')
          .select('id, job_title, company_name, created_at, profiles(full_name)')
          .eq('status', status)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error fetching $status offers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchShortlistedCandidates() async {
    try {
      final data = await Supabase.instance.client
          .from('applications')
          .select('id, job_title, profiles(full_name)')
          .eq('status', 'shortlisted')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error fetching shortlisted candidates: $e");
      return [];
    }
  }

  Future<void> _updateStatus(int applicationId, String newStatus, String message) async {
    setState(() => _busyApplicationId = applicationId);

    try {
      await Supabase.instance.client
          .from('applications')
          .update({
            'status': newStatus,
          })
          .eq('id', applicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        setState(() {
          _busyApplicationId = null;
          _loadOffers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busyApplicationId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showExtendOfferSheet() async {
    final candidates = await _fetchShortlistedCandidates();
    if (!mounted) return;

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No shortlisted candidates available to extend offers to."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int? selectedAppId = candidates.first['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
                  Text("Extend Job Offer", style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(
                    "Select a shortlisted candidate to send an official offer",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text("Select Candidate", style: AppTypography.captionBold.copyWith(color: Colors.white70)),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                      borderRadius: AppBorderRadius.small,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: const Color(0xFF1E293B),
                        value: selectedAppId,
                        isExpanded: true,
                        items: candidates.map((c) {
                          final name = c['profiles']?['full_name'] ?? "Candidate #${c['id']}";
                          final role = c['job_title'] ?? "Role";
                          return DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text("$name ($role)", overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedAppId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text("Offered Compensation / CTC", style: AppTypography.captionBold.copyWith(color: Colors.white70)),
                  SizedBox(height: AppSpacing.xs),
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: r"e.g. ₹18,00,000 / annum or $120k",
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.small,
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.small,
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedAppId != null) {
                          Navigator.pop(ctx);
                          _updateStatus(selectedAppId!, 'offer_sent', "Offer extended successfully!");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Send Official Offer", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 16.0;

    return Stack(
      children: [
        FutureBuilder<List<List<Map<String, dynamic>>>>(
          future: _offersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final pending = snapshot.data?[0] ?? [];
            final secured = snapshot.data?[1] ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _loadOffers());
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  topInset,
                  AppSpacing.lg,
                  100,
                ),
                children: [
                  RecruiterOfferHeader(
                    pendingCount: pending.length,
                    securedCount: secured.length,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Text("PENDING OFFERS (${pending.length})", style: AppTypography.sectionHeader),
                  SizedBox(height: AppSpacing.md),
                  if (pending.isEmpty)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: AppBorderRadius.small,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.mail_outline_rounded, size: 36, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              "No active pending offers.",
                              style: AppTypography.bodyMediumBold,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "+ Extend Offer" below to extend an offer to a candidate.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...pending.map((o) {
                      final date = (o['created_at'] ?? '').toString().split('T').first;
                      final isRowBusy = _busyApplicationId == o['id'];

                      return RecruiterPendingOfferCard(
                        name: o['profiles']?['full_name'] ?? "Candidate #${o['id']}",
                        role: o['job_title'] ?? 'Role',
                        date: date.isNotEmpty ? date : null,
                        isLoading: isRowBusy,
                        onMarkAccepted: () => _updateStatus(o['id'], 'hired', "Candidate officially marked as Hired!"),
                        onCancelOffer: () => _updateStatus(o['id'], 'shortlisted', "Offer revoked, moved back to Shortlist"),
                      );
                    }),
                  SizedBox(height: AppSpacing.xxl),
                  Text("RECENTLY HIRED (${secured.length})", style: AppTypography.sectionHeader),
                  SizedBox(height: AppSpacing.md),
                  if (secured.isEmpty)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: AppBorderRadius.small,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Center(
                        child: Text(
                          "No candidates marked as hired yet.",
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...secured.map((o) {
                      final date = (o['created_at'] ?? '').toString().split('T').first;
                      return RecruiterSecuredOfferTile(
                        name: o['profiles']?['full_name'] ?? "Candidate #${o['id']}",
                        role: o['job_title'] ?? 'Role',
                        date: date.isNotEmpty ? date : null,
                      );
                    }),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 24,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _showExtendOfferSheet,
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Extend Offer", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
