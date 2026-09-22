import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tech & Coding',
    'System Design',
    'AI & Data',
    'Interview Soft Skills',
  ];

  final List<Map<String, dynamic>> _tracks = [
    {
      'title': 'Cracking MNC Tech Interviews',
      'category': 'Tech & Coding',
      'level': 'Intermediate',
      'lessons': 18,
      'duration': '4.5 hrs',
      'tag': 'Popular',
      'tagColor': AppColors.accentAmber,
      'description': 'Master data structures, algorithms, and live coding rounds tailored for top tech employers.',
    },
    {
      'title': 'High-Scale System Architecture',
      'category': 'System Design',
      'level': 'Advanced',
      'lessons': 12,
      'duration': '3.2 hrs',
      'tag': 'Featured',
      'tagColor': AppColors.primary,
      'description': 'Learn caching strategies, distributed databases, microservices, and load balancing.',
    },
    {
      'title': 'Generative AI & LLM Engineering',
      'category': 'AI & Data',
      'level': 'Advanced',
      'lessons': 15,
      'duration': '5.0 hrs',
      'tag': 'Trending',
      'tagColor': AppColors.accent,
      'description': 'Build production-ready LLM agents, vector embeddings, and retrieval-augmented pipelines.',
    },
    {
      'title': 'Executive Pitch & Salary Negotiation',
      'category': 'Interview Soft Skills',
      'level': 'All Levels',
      'lessons': 8,
      'duration': '2.0 hrs',
      'tag': 'Career Boost',
      'tagColor': AppColors.success,
      'description': 'Practical frameworks for structuring elevator pitches, behavioral answers, and counter-offers.',
    },
    {
      'title': 'Python & FastAPI Backend Masterclass',
      'category': 'Tech & Coding',
      'level': 'Beginner to Pro',
      'lessons': 22,
      'duration': '6.5 hrs',
      'tag': 'Core',
      'tagColor': AppColors.info,
      'description': 'Build async REST APIs, integrate database migrations, and handle JWT authentication.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTracks = _selectedCategory == 'All'
        ? _tracks
        : _tracks.where((t) => t['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text(
          "Career Academy",
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          // Hero Banner
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: AppBorderRadius.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppBorderRadius.small,
                      ),
                      child: Text(
                        "PRO PREP",
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  "Level Up Your Interview Readiness",
                  style: AppTypography.headlineLarge.copyWith(color: Colors.white),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  "Curated tracks, practical playbooks, and technical deep-dives to ace your next hiring round.",
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Category Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.large,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Track Cards List
          Text("AVAILABLE TRACKS", style: AppTypography.sectionHeader),
          SizedBox(height: AppSpacing.md),
          ...filteredTracks.map((track) {
            final tagColor = track['tagColor'] as Color;
            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              decoration: AppDecorations.card(),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: AppBorderRadius.small,
                          ),
                          child: Text(
                            track['tag'] as String,
                            style: AppTypography.caption.copyWith(
                              color: tagColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          track['duration'] as String,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      track['title'] as String,
                      style: AppTypography.titleMedium,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      track['description'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Divider(color: AppColors.border, height: 1),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.layers_outlined, size: 16, color: AppColors.textMuted),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              "${track['lessons']} modules • ${track['level']}",
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Opening '${track['title']}' modules..."),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Start Track",
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
