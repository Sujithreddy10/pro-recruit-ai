// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class AIInterviewSimulationScreen extends StatefulWidget {
  const AIInterviewSimulationScreen({super.key});
  @override
  State<AIInterviewSimulationScreen> createState() => _AIInterviewSimulationScreenState();
}

enum _Stage { setup, generating, answering, evaluating, results }

class _AIInterviewSimulationScreenState extends State<AIInterviewSimulationScreen> {
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains("429") || msg.contains("RESOURCE_EXHAUSTED") || msg.contains("quota")) {
      return "Our AI is handling a lot of requests right now. Please wait a minute and try again.";
    }
    return "Something went wrong. Please try again.";
  }
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  Map<String, dynamic>? _selectedApplication;
  final TextEditingController _roleCtrl = TextEditingController();
  _Stage _stage = _Stage.setup;
  String? _error;

  List<String> _questions = [];
  int _currentIndex = 0;
  final TextEditingController _answerCtrl = TextEditingController();
  final List<Map<String, String>> _qaPairs = [];

  Map<String, dynamic>? _evaluation;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _applicationsFuture = userId == null
        ? Future.value([])
        : Supabase.instance.client
            .from('applications')
            .select('id, job_title, company_name')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .then((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  String get _roleTitle =>
      _selectedApplication != null ? (_selectedApplication!['job_title'] as String? ?? '') : _roleCtrl.text.trim();

  Future<void> _startSimulation() async {
    if (_roleTitle.isEmpty) return;
    setState(() {
      _stage = _Stage.generating;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'interview-simulate',
        body: {'mode': 'generate_questions', 'roleTitle': _roleTitle},
      );
      if (res.status != 200) throw 'Server error (${res.status})';
      final data = res.data as Map<String, dynamic>;
      final questions = List<String>.from(data['questions'] as List);
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _qaPairs.clear();
        _stage = _Stage.answering;
      });
    } catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _stage = _Stage.setup;
      });
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    _qaPairs.add({'question': _questions[_currentIndex], 'answer': answer});
    _answerCtrl.clear();
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      await _evaluateSession();
    }
  }

  Future<void> _evaluateSession() async {
    setState(() {
      _stage = _Stage.evaluating;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'interview-simulate',
        body: {'mode': 'evaluate_session', 'roleTitle': _roleTitle, 'qaPairs': _qaPairs},
      );
      if (res.status != 200) throw 'Server error (${res.status})';
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _evaluation = data['evaluation'] as Map<String, dynamic>;
        _stage = _Stage.results;
      });
    } catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _stage = _Stage.answering;
        _currentIndex = _questions.length - 1;
      });
    }
  }

  void _restart() {
    setState(() {
      _stage = _Stage.setup;
      _selectedApplication = null;
      _roleCtrl.clear();
      _questions = [];
      _currentIndex = 0;
      _qaPairs.clear();
      _evaluation = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("AI Interview Simulation", style: AppTypography.titleMedium.copyWith(color: Colors.purple)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.setup:
        return _buildSetup();
      case _Stage.generating:
        return const Center(child: CircularProgressIndicator());
      case _Stage.answering:
        return _buildAnswering();
      case _Stage.evaluating:
        return const Center(child: CircularProgressIndicator());
      case _Stage.results:
        return _buildResults();
    }
  }

  Widget _buildSetup() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicationsFuture,
      builder: (context, snapshot) {
        final applications = snapshot.data ?? [];
        return ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: [
            Text("Practice for a role", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
            SizedBox(height: AppSpacing.sm),
            Text(
              "Get 6 tailored interview questions, answer them here, and get an honest AI debrief at the end.",
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            SizedBox(height: AppSpacing.xl),
            if (applications.isNotEmpty) ...[
              Text("Pick a job you've applied to", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.sm),
              ...applications.map((app) => RadioListTile<Map<String, dynamic>>(
                    value: app,
                    groupValue: _selectedApplication,
                    onChanged: (v) => setState(() {
                      _selectedApplication = v;
                      _roleCtrl.clear();
                    }),
                    title: Text("${app['job_title']} - ${app['company_name']}", style: AppTypography.bodyMedium),
                  )),
              SizedBox(height: AppSpacing.md),
              Text("or", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              SizedBox(height: AppSpacing.md),
            ],
            Text("Practice for any role", style: AppTypography.sectionHeader),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _roleCtrl,
              enabled: _selectedApplication == null,
              decoration: const InputDecoration(hintText: "e.g. Backend Engineer, Sales Executive"),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[
              Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error), maxLines: 3, overflow: TextOverflow.ellipsis),
              SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton(
              onPressed: _roleTitle.isEmpty ? null : _startSimulation,
              child: const Text("Start Mock Interview"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnswering() {
    final progress = (_currentIndex + 1) / _questions.length;
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress, color: Colors.purple),
          SizedBox(height: AppSpacing.sm),
          Text("Question ${_currentIndex + 1} of ${_questions.length}",
              style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(),
            child: Text(_questions[_currentIndex], style: AppTypography.bodyMedium),
          ),
          SizedBox(height: AppSpacing.xl),
          Expanded(
            child: TextField(
              controller: _answerCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: "Type your answer..."),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (_error != null) ...[
            Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error), maxLines: 3, overflow: TextOverflow.ellipsis),
            SizedBox(height: AppSpacing.md),
          ],
          ElevatedButton(
            onPressed: _submitAnswer,
            child: Text(_currentIndex < _questions.length - 1 ? "Next Question" : "Finish & Get Feedback"),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final eval = _evaluation ?? {};
    final score = eval['score'];
    final strengths = List<String>.from(eval['strengths'] ?? []);
    final improvements = List<String>.from(eval['improvements'] ?? []);
    final summary = eval['summary'] as String? ?? '';
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Text("Your Debrief", style: AppTypography.sectionHeader.copyWith(color: AppColors.primary)),
        SizedBox(height: AppSpacing.lg),
        Center(
          child: Column(children: [
            Text("$score", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.purple)),
            Text("/ 100", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ]),
        ),
        SizedBox(height: AppSpacing.xl),
        Text(summary, style: AppTypography.bodyMedium),
        SizedBox(height: AppSpacing.xl),
        if (strengths.isNotEmpty) ...[
          Text("Strengths", style: AppTypography.sectionHeader.copyWith(color: AppColors.success)),
          SizedBox(height: AppSpacing.sm),
          ...strengths.map((s) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text("- $s", style: AppTypography.bodyMedium),
              )),
          SizedBox(height: AppSpacing.xl),
        ],
        if (improvements.isNotEmpty) ...[
          Text("Areas to improve", style: AppTypography.sectionHeader.copyWith(color: AppColors.warning)),
          SizedBox(height: AppSpacing.sm),
          ...improvements.map((s) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text("- $s", style: AppTypography.bodyMedium),
              )),
          SizedBox(height: AppSpacing.xl),
        ],
        ElevatedButton(onPressed: _restart, child: const Text("Practice Again")),
      ],
    );
  }
}
