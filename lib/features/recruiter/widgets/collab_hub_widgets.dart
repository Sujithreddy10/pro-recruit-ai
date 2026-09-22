import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CollabHubHeader extends StatelessWidget {
  const CollabHubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Colors.deepPurple]),
        borderRadius: AppBorderRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("COLLAB HUB", style: AppTypography.sectionHeader.copyWith(color: Colors.purple.shade100)),
          SizedBox(height: AppSpacing.xs),
          Text(
            "Team Notes on Candidates",
            style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 16),
          ),
          Text(
            "Shared across your whole recruiting team",
            style: AppTypography.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class CollabCandidateCard extends StatelessWidget {
  final String candidateName;
  final String jobTitle;
  final String companyName;
  final int noteCount;
  final VoidCallback onTap;

  const CollabCandidateCard({
    super.key,
    required this.candidateName,
    required this.jobTitle,
    required this.companyName,
    required this.noteCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: AppBorderRadius.small,
              ),
              child: const Icon(Icons.forum_outlined, color: Colors.deepPurple, size: 20),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidateName, style: AppTypography.bodyMediumBold),
                  Text(
                    "$jobTitle @ $companyName",
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: AppDecorations.pill(Colors.deepPurple),
              child: Text(
                "$noteCount ${noteCount == 1 ? 'note' : 'notes'}",
                style: AppTypography.captionBold.copyWith(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollabNotesSheet extends StatefulWidget {
  final Map<String, dynamic> application;

  const CollabNotesSheet({super.key, required this.application});

  @override
  State<CollabNotesSheet> createState() => _CollabNotesSheetState();
}

class _CollabNotesSheetState extends State<CollabNotesSheet> {
  late Future<List<Map<String, dynamic>>> _notesFuture;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _notesFuture = _fetchNotes();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchNotes() async {
    final data = await Supabase.instance.client
        .from('candidate_notes')
        .select('id, note_text, created_at, recruiter_id, profiles(full_name)')
        .eq('application_id', widget.application['id'])
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _sendNote() async {
    if (_noteCtrl.text.trim().isEmpty || _isSending) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    try {
      await Supabase.instance.client.from('candidate_notes').insert({
        'application_id': widget.application['id'],
        'recruiter_id': userId,
        'note_text': _noteCtrl.text.trim(),
      });
      _noteCtrl.clear();
      setState(() {
        _notesFuture = _fetchNotes();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.application['profiles']?['full_name'] ?? 'Candidate', style: AppTypography.titleMedium),
                      Text(
                        "${widget.application['job_title']} @ ${widget.application['company_name']}",
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
                }
                final notes = snapshot.data ?? [];
                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        "No notes yet. Be the first to leave one for your team.",
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final n = notes[i];
                    final isMine = n['recruiter_id'] == currentUserId;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
                        padding: EdgeInsets.all(AppSpacing.md),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.deepPurple.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                          borderRadius: AppBorderRadius.medium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['profiles']?['full_name'] ?? 'Recruiter',
                              style: AppTypography.captionBold.copyWith(color: Colors.deepPurple),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(n['note_text'] ?? '', style: AppTypography.bodySmall),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              n['created_at']?.toString().split('.').first ?? '',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Add a note for your team...",
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.edit_note, color: Colors.deepPurple, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.small,
                        borderSide: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.small,
                        borderSide: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.small,
                        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Colors.deepPurple]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendNote,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
