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
    _candidatesFuture.then(_trackProfileViews);
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
        Supabase.instance.client.rpc('increment_profile_views', params: {'target_profile_id': profileId});
      }
    }
  }

  Future<void> _loadSavedCandidateIds() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client.from('saved_candidates').select('candidate_id').eq('recruiter_id', userId);
      final ids = (data as List).map((r) => r['candidate_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
      if (mounted) setState(() => _savedCandidateIds.addAll(ids));
    } catch (_) {}
  }

  Future<void> _toggleSaveCandidate(String candidateId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || candidateId.isEmpty) return;

    final isSaved = _savedCandidateIds.contains(candidateId);
    setState(() => isSaved ? _savedCandidateIds.remove(candidateId) : _savedCandidateIds.add(candidateId));

    try {
      if (isSaved) {
        await Supabase.instance.client.from('saved_candidates').delete().eq('recruiter_id', userId).eq('candidate_id', candidateId);
      } else {
        await Supabase.instance.client.from('saved_candidates').insert({'recruiter_id': userId, 'candidate_id': candidateId});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSaved ? 'Candidate removed from saved' : 'Candidate saved'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaved ? _savedCandidateIds.add(candidateId) : _savedCandidateIds.remove(candidateId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update saved candidate: $e')));
      }
    }
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No resume uploaded")));
      return;
    }
    try {
      final signedUrl = await Supabase.instance.client.storage.from('resumes').createSignedUrl(resumePath, 60 * 5);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open resume URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load resume: $e"), backgroundColor: AppColors.error));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Offer Sent"), backgroundColor: AppColors.info));
        setState(() {
          _candidatesFuture = _fetchCandidates();
          _candidatesFuture.then(_trackProfileViews);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send offer: $e"), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _editNotesAndRatingDialog(Map<String, dynamic> c) async {
    await showDialog(
      context: context,
      builder: (ctx) => NotesAndRatingDialog(
        initialNotes: c['recruiter_notes'] as String?,
        initialRating: c['recruiter_rating'] as int?,
        onSave: (notes, rating) async {
          try {
            await Supabase.instance.client.from('applications').update({
              'recruiter_notes': notes,
              'recruiter_rating': rating,
            }).eq('id', c['id']);
            if (mounted) {
              setState(() {
                _candidatesFuture = _fetchCandidates();
                _candidatesFuture.then(_trackProfileViews);
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e"), backgroundColor: AppColors.error));
            }
          }
        },
      ),
    );
  }

  Future<void> _startOrOpenConversation(String candidateId, String candidateName, String jobTitle, String companyName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || candidateId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .upsert(
            {'candidate_id': candidateId, 'recruiter_id': userId, 'job_title': jobTitle, 'company_name': companyName},
            onConflict: 'candidate_id,recruiter_id',
          )
          .select('id')
          .single();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ChatScreen(
              conversationId: row['id'].toString(),
              otherPartyName: candidateName,
              contextLabel: "$jobTitle · $companyName",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open conversation: $e")));
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
          final counts = <String, int>{for (final s in _statusOptions.skip(1)) s: all.where((c) => c['status'] == s).length};

          final filtered = all.where((c) {
            final matchesStatus = _statusFilter == 'all' || c['status'] == _statusFilter;
            final name = (c['profiles']?['full_name'] ?? '').toString().toLowerCase();
            final job = (c['job_title'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return matchesStatus && (_searchQuery.isEmpty || name.contains(q) || job.contains(q));
          }).toList();

          return Column(
            children: [
              CandidateCrmSearchBar(onChanged: (v) => setState(() => _searchQuery = v)),
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
                child: CandidateCrmListView(
                  candidates: filtered,
                  savedCandidateIds: _savedCandidateIds,
                  onViewResume: _viewResume,
                  onMessage: _startOrOpenConversation,
                  onEditNotesAndRating: _editNotesAndRatingDialog,
                  onToggleSave: _toggleSaveCandidate,
                  onSendOffer: _sendOffer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
