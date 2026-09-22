import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/candidate_crm_widgets.dart';

class CandidateCRMScreen extends StatefulWidget {
  const CandidateCRMScreen({super.key});

  @override
  State<CandidateCRMScreen> createState() => _CandidateCRMScreenState();
}

class _CandidateCRMScreenState extends State<CandidateCRMScreen> {
  late Future<List<Map<String, dynamic>>> _candidatesFuture;
  final Set<String> _viewedCandidateIds = {};
  final Set<String> _savedCandidateIds = {};
  String _statusFilter = 'all';
  String _searchQuery = '';

  static const _statusOptions = ['all', 'applied', 'shortlisted', 'offer_sent', 'hired', 'rejected'];

  @override
  void initState() {
    super.initState();
    _candidatesFuture = _fetchCandidates();
    _candidatesFuture.then((rows) => _trackProfileViews(rows));
    _loadSavedCandidateIds();
  }

  Future<List<Map<String, dynamic>>> _fetchCandidates() async {
    final data = await Supabase.instance.client
        .from('applications')
        .select('id, user_id, job_title, company_name, status, recruiter_notes, recruiter_rating, profiles(id, full_name, resume_path)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  void _trackProfileViews(List<Map<String, dynamic>> candidates) {
    for (final c in candidates) {
      final profileId = c['profiles']?['id']?.toString();
      if (profileId != null && profileId.isNotEmpty && !_viewedCandidateIds.contains(profileId)) {
        _viewedCandidateIds.add(profileId);
        Supabase.instance.client.rpc('increment_profile_views', params: {
          'target_user_id': profileId,
        }).catchError((_) {});
      }
    }
  }

  Future<void> _loadSavedCandidateIds() async {
    try {
      final saved = await _fetchSavedCandidateIds();
      if (mounted) {
        setState(() {
          _savedCandidateIds
            ..clear()
            ..addAll(saved);
        });
      }
    } catch (_) {}
  }

  Future<Set<String>> _fetchSavedCandidateIds() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return <String>{};

    final data = await Supabase.instance.client
        .from('saved_candidates')
        .select('candidate_id')
        .eq('recruiter_id', userId);

    return (data as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['candidate_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _toggleSaveCandidate(String candidateId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || candidateId.isEmpty) return;

    final isSaved = _savedCandidateIds.contains(candidateId);
    setState(() {
      if (isSaved) {
        _savedCandidateIds.remove(candidateId);
      } else {
        _savedCandidateIds.add(candidateId);
      }
    });

    try {
      if (isSaved) {
        await Supabase.instance.client
            .from('saved_candidates')
            .delete()
            .eq('recruiter_id', userId)
            .eq('candidate_id', candidateId);
      } else {
        await Supabase.instance.client.from('saved_candidates').insert({
          'recruiter_id': userId,
          'candidate_id': candidateId,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSaved ? 'Candidate removed from saved' : 'Candidate saved'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isSaved) {
            _savedCandidateIds.add(candidateId);
          } else {
            _savedCandidateIds.remove(candidateId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update saved candidate: $e')),
        );
      }
    }
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded")),
      );
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('resumes')
          .createSignedUrl(resumePath, 60 * 5);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open resume URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load resume: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendOffer(int applicationId) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': 'offer_sent', 'status_updated_at': DateTime.now().toIso8601String()})
          .eq('id', applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Offer Sent"), backgroundColor: AppColors.info),
        );
        setState(() {
          _candidatesFuture = _fetchCandidates();
          _candidatesFuture.then((rows) => _trackProfileViews(rows));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send offer: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _editNotesAndRatingDialog(Map<String, dynamic> c) async {
    final notesCtrl = TextEditingController(text: c['recruiter_notes'] ?? '');
    int rating = (c['recruiter_rating'] as int?) ?? 0;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Notes & Rating", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rating", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () => setDialogState(() => rating = i + 1),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Private Notes",
                    hintText: "Only visible to your recruiting team",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save")),
          ],
        ),
      ),
    );
    if (result == true) {
      try {
        await Supabase.instance.client.from('applications').update({
          'recruiter_notes': notesCtrl.text.trim(),
          'recruiter_rating': rating == 0 ? null : rating,
        }).eq('id', c['id']);
        if (mounted) {
          setState(() {
            _candidatesFuture = _fetchCandidates();
            _candidatesFuture.then((rows) => _trackProfileViews(rows));
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'shortlisted':
        return AppColors.success;
      case 'offer_sent':
        return AppColors.info;
      case 'hired':
        return Colors.teal;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _startOrOpenConversation(String candidateId, String candidateName, String jobTitle, String companyName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || candidateId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .upsert(
            {
              'candidate_id': candidateId,
              'recruiter_id': userId,
              'job_title': jobTitle,
              'company_name': companyName,
            },
            onConflict: 'candidate_id,recruiter_id',
          )
          .select('id')
          .single();
      final conversationId = row['id'].toString();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ChatScreen(
              conversationId: conversationId,
              otherPartyName: candidateName,
              contextLabel: "$jobTitle · $companyName",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open conversation: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Candidate CRM", style: AppTypography.titleMedium.copyWith(color: Colors.deepOrange)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _candidatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final all = snapshot.data ?? [];

          final counts = <String, int>{};
          for (final s in _statusOptions.skip(1)) {
            counts[s] = all.where((c) => c['status'] == s).length;
          }

          final filtered = all.where((c) {
            final matchesStatus = _statusFilter == 'all' || c['status'] == _statusFilter;
            final name = (c['profiles']?['full_name'] ?? '').toString().toLowerCase();
            final job = (c['job_title'] ?? '').toString().toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                name.contains(_searchQuery.toLowerCase()) ||
                job.contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(30)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: "Search candidates, roles...",
                      prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: CandidateCrmFilterBar(
                  selectedFilter: _statusFilter,
                  totalCount: all.length,
                  counts: counts,
                  onFilterSelected: (key) => setState(() => _statusFilter = key),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt_off_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
                            SizedBox(height: AppSpacing.sm),
                            Text("No candidates found.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final profile = c['profiles'];
                          final name = profile?['full_name'] ?? 'Unknown Candidate';
                          final resumePath = profile?['resume_path'];
                          final status = (c['status'] ?? 'applied').toString();
                          final color = _statusColor(status);
                          final profileId = (profile?['id'] ?? '').toString();

                          return CandidateCrmCard(
                            name: name,
                            resumePath: resumePath,
                            jobTitle: (c['job_title'] ?? 'N/A').toString(),
                            companyName: (c['company_name'] ?? 'N/A').toString(),
                            status: status,
                            statusColor: color,
                            rating: (c['recruiter_rating'] as int?) ?? 0,
                            isSaved: _savedCandidateIds.contains(profileId),
                            onViewResume: () => _viewResume(resumePath),
                            onMessage: () => _startOrOpenConversation(
                              profileId,
                              name,
                              (c['job_title'] ?? '').toString(),
                              (c['company_name'] ?? '').toString(),
                            ),
                            onEditNotesAndRating: () => _editNotesAndRatingDialog(c),
                            onToggleSave: () => _toggleSaveCandidate(profileId),
                            onSendOffer: status == 'shortlisted' ? () => _sendOffer(c['id']) : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
