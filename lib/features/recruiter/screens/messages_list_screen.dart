import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';

class RecruiterMessagesListScreen extends StatefulWidget {
  const RecruiterMessagesListScreen({super.key});

  @override
  State<RecruiterMessagesListScreen> createState() => _RecruiterMessagesListScreenState();
}

class _RecruiterMessagesListScreenState extends State<RecruiterMessagesListScreen> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _fetchConversations();
  }

  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('conversations')
        .select('id, job_title, company_name, last_message_at, candidate:profiles!candidate_id(full_name)')
        .eq('recruiter_id', userId)
        .order('last_message_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Messages", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  SizedBox(height: AppSpacing.md),
                  Text("No conversations yet. Message a candidate from the CRM to get started.",
                      textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: conversations.length,
            itemBuilder: (context, i) {
              final conv = conversations[i];
              final candidateName = conv['candidate']?['full_name'] ?? 'Candidate';
              final contextLabel = [
                if ((conv['job_title'] ?? '').toString().isNotEmpty) conv['job_title'],
                if ((conv['company_name'] ?? '').toString().isNotEmpty) conv['company_name'],
              ].join(' · ');
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: AppBorderRadius.medium,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.medium,
                    side: BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(candidateName.isNotEmpty ? candidateName[0].toUpperCase() : '?',
                        style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary)),
                  ),
                  title: Text(candidateName, style: AppTypography.bodyMediumBold),
                  subtitle: contextLabel.isNotEmpty
                      ? Text(contextLabel, style: AppTypography.caption.copyWith(color: AppColors.textMuted))
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatScreen(
                        conversationId: conv['id'].toString(),
                        otherPartyName: candidateName,
                        contextLabel: contextLabel,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          );
        },
      ),
    );
  }
}
