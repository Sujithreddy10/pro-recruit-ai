import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';

class RecruiterSavedCandidatesScreen extends StatefulWidget {
  const RecruiterSavedCandidatesScreen({super.key});

  @override
  State<RecruiterSavedCandidatesScreen> createState() => _RecruiterSavedCandidatesScreenState();
}

class _RecruiterSavedCandidatesScreenState extends State<RecruiterSavedCandidatesScreen> {
  late Future<List<Map<String, dynamic>>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _savedFuture = _fetchSaved();
  }

  void _refresh() {
    setState(() {
      _savedFuture = _fetchSaved();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSaved() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('saved_candidates')
        .select('id, candidate_id, profiles!candidate_id(id, full_name, resume_path)')
        .eq('recruiter_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _unsave(String savedRowId) async {
    try {
      await Supabase.instance.client.from('saved_candidates').delete().eq('id', savedRowId);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove: $e")));
      }
    }
  }

  Future<void> _viewResume(String? resumePath) async {
    if (resumePath == null || resumePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded by this candidate.")),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load resume: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _startOrOpenConversation(String candidateId, String candidateName) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || candidateId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .upsert(
            {
              'candidate_id': candidateId,
              'recruiter_id': userId,
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Saved Candidates", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _savedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final saved = snapshot.data ?? [];
          if (saved.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  SizedBox(height: AppSpacing.md),
                  Text("No saved candidates yet. Bookmark someone from the CRM to build your talent pool.",
                      textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: saved.length,
            itemBuilder: (context, i) {
              final row = saved[i];
              final profile = row['profiles'] as Map<String, dynamic>? ?? {};
              final name = profile['full_name'] ?? 'Unknown Candidate';
              final resumePath = profile['resume_path'];
              return Container(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorderRadius.medium,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary)),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(name, style: AppTypography.bodyMediumBold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.description_outlined, color: Colors.deepOrange, size: 20),
                      onPressed: () => _viewResume(resumePath),
                      tooltip: "View Resume",
                    ),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                      onPressed: () => _startOrOpenConversation((profile['id'] ?? '').toString(), name),
                      tooltip: "Message",
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark, color: AppColors.primary),
                      onPressed: () => _unsave(row['id'].toString()),
                      tooltip: "Remove from saved",
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
