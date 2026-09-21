import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class ProfileViewsScreen extends StatefulWidget {
  const ProfileViewsScreen({super.key});

  @override
  State<ProfileViewsScreen> createState() => _ProfileViewsScreenState();
}

class _ProfileViewsScreenState extends State<ProfileViewsScreen> {
  late Future<List<Map<String, dynamic>>> _viewsFuture;

  @override
  void initState() {
    super.initState();
    _viewsFuture = _fetchViews();
  }

  Future<List<Map<String, dynamic>>> _fetchViews() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await Supabase.instance.client
        .from('profile_views')
        .select('id, created_at, recruiter:profiles!recruiter_id(full_name)')
        .eq('candidate_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(data);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Profile Views", style: AppTypography.titleMedium),
        centerTitle: false,
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _viewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final views = snapshot.data ?? [];
          if (views.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.visibility_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  SizedBox(height: AppSpacing.md),
                  Text("No recruiters have viewed your profile yet.",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ]),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: views.length,
            itemBuilder: (context, i) {
              final v = views[i];
              final recruiter = v['recruiter'] as Map<String, dynamic>? ?? {};
              final name = recruiter['full_name'] ?? 'A recruiter';
              final createdAt = DateTime.tryParse(v['created_at'] ?? '') ?? DateTime.now();
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
                      child: Icon(Icons.visibility_outlined, color: AppColors.primary, size: 18),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$name viewed your profile", style: AppTypography.bodyMediumBold),
                          SizedBox(height: 2),
                          Text(_timeAgo(createdAt), style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
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
