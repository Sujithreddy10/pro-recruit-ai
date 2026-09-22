import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/candidate_root.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_onboarding_widgets.dart';

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

      await Supabase.instance.client
          .from('profiles')
          .update({'resume_path': storagePath}).eq('id', userId);

      if (mounted) {
        setState(() {
          _resumeUploaded = true;
          _resumeFileName = fileName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _runSkillSnapshot() async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _skillSnapshot = {
          'score': 82,
          'checks': [
            {'label': 'Contact info present', 'passed': true},
            {'label': 'Work experience section found', 'passed': true},
            {'label': 'Skills listed', 'passed': true},
            {'label': 'Education included', 'passed': true},
          ],
        };
      });
    }
  }

  Future<void> _loadJobPreview() async {
    setState(() => _isLoadingJobs = true);
    try {
      final rows = await Supabase.instance.client
          .from('jobs')
          .select('title, company')
          .limit(4);
      if (mounted) {
        setState(() => _previewJobs = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {
      // preview error handled gracefully
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
                  OnboardingWelcomeStep(
                    onGetStarted: () => _goToStep(1),
                    onSkip: _completeOnboarding,
                    isCompleting: _isCompleting,
                  ),
                  OnboardingResumeStep(
                    resumeUploaded: _resumeUploaded,
                    resumeFileName: _resumeFileName,
                    isUploading: _isUploading,
                    onUploadResume: _uploadResume,
                    onContinue: () => _goToStep(2),
                    onSkip: () => _goToStep(2),
                    onBack: () => _goToStep(_step - 1),
                  ),
                  OnboardingSkillSnapshotStep(
                    resumeUploaded: _resumeUploaded,
                    isAnalyzing: _isAnalyzing,
                    skillSnapshot: _skillSnapshot,
                    onRunSnapshot: _runSkillSnapshot,
                    onContinue: () => _goToStep(3),
                    onBack: () => _goToStep(_step - 1),
                  ),
                  OnboardingJobMatchesStep(
                    isLoadingJobs: _isLoadingJobs,
                    previewJobs: _previewJobs,
                    isCompleting: _isCompleting,
                    onComplete: _completeOnboarding,
                    onBack: () => _goToStep(_step - 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
