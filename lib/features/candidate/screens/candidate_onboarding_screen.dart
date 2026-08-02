import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/candidate_root.dart';

class CandidateOnboardingScreen extends StatefulWidget {
  const CandidateOnboardingScreen({super.key});

  @override
  State<CandidateOnboardingScreen> createState() => _CandidateOnboardingScreenState();
}

class _CandidateOnboardingScreenState extends State<CandidateOnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;
  static const int _totalSteps = 4;

  bool _isUploading = false;
  bool _resumeUploaded = false;
  String? _resumeFileName;

  bool _isAnalyzing = false;
  Map<String, dynamic>? _skillSnapshot;

  bool _isLoadingJobs = false;
  List<Map<String, dynamic>> _previewJobs = [];

  bool _isCompleting = false;

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    if (step == 2 && _resumeUploaded && _skillSnapshot == null) {
      _runSkillSnapshot();
    }
    if (step == 3 && _previewJobs.isEmpty) {
      _loadJobPreview();
    }
  }

  Future<void> _uploadResume() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    setState(() => _isUploading = true);
    try {
      await Supabase.instance.client.storage
          .from('resumes')
          .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

      await Supabase.instance.client.from('candidate_resumes').insert({
        'candidate_id': userId,
        'storage_path': storagePath,
        'file_name': fileName,
        'label': fileName.replaceAll('.pdf', '').replaceAll('_', ' '),
        'is_primary': true,
      });

      () async {
        try {
          await Supabase.instance.client.functions.invoke('parse-resume', body: {'storagePath': storagePath});
        } catch (e) {
          debugPrint("parse-resume failed: $e");
        }
      }();

      if (mounted) {
        setState(() {
          _resumeUploaded = true;
          _resumeFileName = fileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _runSkillSnapshot() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isAnalyzing = true);
    try {
      // Give parse-resume a moment to finish writing resume_text before we
      // ask for the analysis, since it runs fire-and-forget on upload.
      await Future.delayed(const Duration(seconds: 2));
      final response = await Supabase.instance.client.functions.invoke(
        'extract-resume-text',
        body: {'userId': userId},
      );
      if (response.data?['general'] != null) {
        setState(() => _skillSnapshot = Map<String, dynamic>.from(response.data['general']));
      }
    } catch (e) {
      debugPrint("skill snapshot failed: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _loadJobPreview() async {
    setState(() => _isLoadingJobs = true);
    try {
      final jobs = await Supabase.instance.client.from('jobs').select('*').limit(4);
      if (mounted) setState(() => _previewJobs = List<Map<String, dynamic>>.from(jobs));
    } catch (e) {
      debugPrint("job preview failed: $e");
    } finally {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isCompleting = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'onboarding_completed': true}).eq('id', userId);
    } catch (e) {
      debugPrint("failed to mark onboarding complete: $e");
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (c) => const CandidateRoot()),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF1E40AF) : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcomeStep(),
                  _resumeStep(),
                  _skillSnapshotStep(),
                  _jobMatchesStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget content,
    required Widget primaryButton,
    Widget? secondaryButton,
    bool showBack = true,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => _goToStep(_step - 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          SizedBox(height: AppSpacing.md),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: AppBorderRadius.large,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary)),
          SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          SizedBox(height: AppSpacing.xl),
          Expanded(child: content),
          primaryButton,
          if (secondaryButton != null) ...[SizedBox(height: AppSpacing.sm), secondaryButton],
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Widget _welcomeStep() {
    return _stepScaffold(
      showBack: false,
      icon: Icons.waving_hand_rounded,
      title: "Welcome to Hylo",
      subtitle: "Let's get your profile match-ready in 3 quick steps.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomePoint(Icons.upload_file_rounded, "Upload your resume"),
          _welcomePoint(Icons.psychology_outlined, "Get an instant AI skill snapshot"),
          _welcomePoint(Icons.work_outline_rounded, "See real jobs waiting for you"),
        ],
      ),
      primaryButton: _primaryButton("Get Started", () => _goToStep(1)),
      secondaryButton: TextButton(
        onPressed: _isCompleting ? null : _completeOnboarding,
        child: Text("Skip for now", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      ),
    );
  }

  Widget _welcomePoint(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E40AF), size: 22),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _resumeStep() {
    return _stepScaffold(
      icon: Icons.upload_file_rounded,
      title: "Upload Your Resume",
      subtitle: "We'll use this to find better matches and generate your skill snapshot.",
      content: Center(
        child: _resumeUploaded
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 48),
                  SizedBox(height: AppSpacing.sm),
                  Text(_resumeFileName ?? "Resume uploaded", style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                ],
              )
            : Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted),
      ),
      primaryButton: _resumeUploaded
          ? _primaryButton("Continue", () => _goToStep(2))
          : _primaryButton("Choose PDF", _uploadResume, loading: _isUploading),
      secondaryButton: TextButton(
        onPressed: () => _goToStep(2),
        child: Text("Skip this step", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      ),
    );
  }

  Widget _skillSnapshotStep() {
    Widget content;
    if (!_resumeUploaded) {
      content = Center(
        child: Text(
          "Upload a resume to unlock your AI skill snapshot.",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    } else if (_isAnalyzing) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_skillSnapshot == null) {
      content = Center(
        child: TextButton(onPressed: _runSkillSnapshot, child: const Text("Analyze My Resume")),
      );
    } else {
      final score = _skillSnapshot!['score'] ?? 0;
      final checks = (_skillSnapshot!['checks'] as List?) ?? [];
      content = ListView(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: AppBorderRadius.large,
            ),
            child: Row(
              children: [
                Text("$score", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text("Resume Quality Score", style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ...checks.take(4).map((c) => ListTile(
                dense: true,
                leading: Icon(
                  c['passed'] == true ? Icons.check_circle : Icons.cancel,
                  color: c['passed'] == true ? AppColors.success : AppColors.textMuted,
                  size: 20,
                ),
                title: Text(c['label'] ?? '', style: AppTypography.bodySmall),
              )),
        ],
      );
    }

    return _stepScaffold(
      icon: Icons.psychology_outlined,
      title: "Your Skill Snapshot",
      subtitle: "A quick AI read on how your resume looks to recruiters.",
      content: content,
      primaryButton: _primaryButton("Continue", () => _goToStep(3)),
    );
  }

  Widget _jobMatchesStep() {
    Widget content;
    if (_isLoadingJobs) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_previewJobs.isEmpty) {
      content = Center(
        child: Text("No jobs available right now — check back soon.", style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
      );
    } else {
      content = ListView.builder(
        itemCount: _previewJobs.length,
        itemBuilder: (c, i) {
          final job = _previewJobs[i];
          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorderRadius.large,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                    borderRadius: AppBorderRadius.small,
                  ),
                  child: const Icon(Icons.work_outline_rounded, color: Color(0xFF1E40AF), size: 20),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title'] ?? 'Untitled Role', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                      Text(job['company'] ?? '', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return _stepScaffold(
      icon: Icons.work_outline_rounded,
      title: "Jobs Waiting For You",
      subtitle: "A preview of real openings on Hylo right now.",
      content: content,
      primaryButton: _primaryButton("Get Started", _completeOnboarding, loading: _isCompleting),
    );
  }
}
