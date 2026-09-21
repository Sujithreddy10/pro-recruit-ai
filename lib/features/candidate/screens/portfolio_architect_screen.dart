import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class PortfolioArchitectScreen extends StatefulWidget {
  const PortfolioArchitectScreen({super.key});
  @override
  State<PortfolioArchitectScreen> createState() => _PortfolioArchitectScreenState();
}

class _PortfolioArchitectScreenState extends State<PortfolioArchitectScreen> {
  final TextEditingController _targetRoleCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains("429") || msg.contains("RESOURCE_EXHAUSTED") || msg.contains("quota")) {
      return "Our AI is handling a lot of requests right now. Please wait a minute and try again.";
    }
    return "Something went wrong. Please try again.";
  }

  Future<void> _generate() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final skills = await Supabase.instance.client
          .from('candidate_skills')
          .select('skill_name, category, proficiency')
          .eq('user_id', userId);
      final projects = await Supabase.instance.client
          .from('candidate_projects')
          .select('title, description, tech_tags')
          .eq('user_id', userId);
      final certificates = await Supabase.instance.client
          .from('candidate_certificates')
          .select('title, issuing_org')
          .eq('user_id', userId);

      if ((projects as List).isEmpty && (skills as List).isEmpty) {
        setState(() {
          _error = "Add a few skills or projects to your profile first, then come back here.";
          _isLoading = false;
        });
        return;
      }

      final res = await Supabase.instance.client.functions.invoke(
        'portfolio-architect',
        body: {
          'skills': skills,
          'projects': projects,
          'certificates': certificates,
          'targetRole': _targetRoleCtrl.text.trim(),
        },
      );
      if (res.status != 200) throw 'Server error (${res.status})';
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _result = data['result'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _targetRoleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("Portfolio Architect", style: AppTypography.titleMedium.copyWith(color: Colors.indigo)),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: [
            Text("Builds a portfolio structure and polished project pitches from your real profile data.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _targetRoleCtrl,
              decoration: const InputDecoration(labelText: "Target Role (optional)", hintText: "e.g. Frontend Developer"),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error), maxLines: 3, overflow: TextOverflow.ellipsis),
              SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _generate,
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Build My Portfolio Plan"),
            ),
            if (_result != null) ...[
              SizedBox(height: AppSpacing.xl),
              Text("Suggested Structure", style: AppTypography.sectionHeader.copyWith(color: Colors.indigo)),
              SizedBox(height: AppSpacing.sm),
              ...List<String>.from(_result!['structure'] ?? []).map((s) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text("- $s", style: AppTypography.bodyMedium),
                  )),
              SizedBox(height: AppSpacing.xl),
              Text("Project Pitches", style: AppTypography.sectionHeader.copyWith(color: Colors.indigo)),
              SizedBox(height: AppSpacing.sm),
              ...List<dynamic>.from(_result!['projectPitches'] ?? []).map((p) => Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    padding: EdgeInsets.all(AppSpacing.lg),
                    decoration: AppDecorations.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title'] as String? ?? '', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: AppSpacing.xs),
                        Text(p['pitch'] as String? ?? '', style: AppTypography.bodyMedium),
                      ],
                    ),
                  )),
              SizedBox(height: AppSpacing.xl),
              Text("Summary", style: AppTypography.sectionHeader.copyWith(color: Colors.indigo)),
              SizedBox(height: AppSpacing.sm),
              Text(_result!['summary'] as String? ?? '', style: AppTypography.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
