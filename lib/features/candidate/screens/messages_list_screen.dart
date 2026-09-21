import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
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
        .select('id, job_title, company_name, last_message_at, recruiter:profiles!recruiter_id(full_name)')
        .eq('candidate_id', userId)
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
                  Text("No conversations yet. Message a recruiter from a job listing to get started.",
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
              final recruiterName = conv['recruiter']?['full_name'] ?? 'Recruiter';
              final contextLabel = [
                if ((conv['job_title'] ?? '').toString().isNotEmpty) conv['job_title'],
                if ((conv['company_name'] ?? '').toString().isNotEmpty) conv['company_name'],
              ].join(' · ');
              return Container(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorderRadius.medium,
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(recruiterName.isNotEmpty ? recruiterName[0].toUpperCase() : '?',
                        style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary)),
                  ),
                  title: Text(recruiterName, style: AppTypography.bodyMediumBold),
                  subtitle: contextLabel.isNotEmpty
                      ? Text(contextLabel, style: AppTypography.caption.copyWith(color: AppColors.textMuted))
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ChatScreen(
                        conversationId: conv['id'].toString(),
                        otherPartyName: recruiterName,
                        contextLabel: contextLabel,
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
