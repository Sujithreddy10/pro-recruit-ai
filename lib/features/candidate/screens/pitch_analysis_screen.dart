import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/candidate/widgets/candidate_pitch_widgets.dart';

class PitchAnalysisScreen extends StatefulWidget {
  const PitchAnalysisScreen({super.key});
  @override
  State<PitchAnalysisScreen> createState() => _PitchAnalysisScreenState();
}

class _PitchAnalysisScreenState extends State<PitchAnalysisScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _transcript = '';
  Timer? _timer;
  int _elapsedSeconds = 0;
  Map<String, dynamic>? _results;

  static const _fillerWords = ['um', 'uh', 'like', 'you know', 'so', 'basically', 'actually', 'literally'];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Speech error: ${err.errorMsg}"), backgroundColor: AppColors.error),
          );
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) _stopListening();
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  void _startListening() {
    setState(() {
      _transcript = '';
      _elapsedSeconds = 0;
      _results = null;
      _isListening = true;
    });

    // ignore: deprecated_member_use
    _speech.listen(
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
      },
      // ignore: deprecated_member_use
      listenFor: const Duration(minutes: 5),
      // ignore: deprecated_member_use
      pauseFor: const Duration(seconds: 4),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopListening() {
    _speech.stop();
    _timer?.cancel();
    setState(() {
      _isListening = false;
      _results = _computeResults();
    });
  }

  Map<String, dynamic> _computeResults() {
    final words = _transcript.trim().isEmpty ? <String>[] : _transcript.trim().split(RegExp(r'\s+'));
    final wordCount = words.length;
    final minutes = _elapsedSeconds / 60.0;
    final wpm = minutes > 0 ? (wordCount / minutes).round() : 0;

    final lowerTranscript = ' ${_transcript.toLowerCase()} ';
    final fillerCounts = <String, int>{};
    int totalFillers = 0;
    for (final f in _fillerWords) {
      final matches = RegExp(' ${RegExp.escape(f)} ').allMatches(lowerTranscript).length;
      if (matches > 0) {
        fillerCounts[f] = matches;
        totalFillers += matches;
      }
    }

    final fillerRate = wordCount > 0 ? (totalFillers / wordCount * 100) : 0.0;

    String paceLabel;
    Color paceColor;
    if (wpm == 0) {
      paceLabel = "No speech detected";
      paceColor = AppColors.textMuted;
    } else if (wpm < 110) {
      paceLabel = "Slower than average";
      paceColor = AppColors.warning;
    } else if (wpm <= 160) {
      paceLabel = "Good conversational pace";
      paceColor = AppColors.success;
    } else {
      paceLabel = "Faster than average";
      paceColor = AppColors.warning;
    }

    return {
      'wordCount': wordCount,
      'wpm': wpm,
      'paceLabel': paceLabel,
      'paceColor': paceColor,
      'fillerCounts': fillerCounts,
      'totalFillers': totalFillers,
      'fillerRate': fillerRate,
      'duration': _elapsedSeconds,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Pitch Analysis", style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.error),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          const PitchHeaderBanner(),
          SizedBox(height: AppSpacing.xl),
          if (!_speechAvailable)
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card(),
              child: Text(
                "Speech recognition isn't available on this device, or microphone permission was denied.",
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            )
          else ...[
            PitchRecordingControl(
              isListening: _isListening,
              formattedDuration: _formatDuration(_elapsedSeconds),
              onTap: _isListening ? _stopListening : _startListening,
            ),
            SizedBox(height: AppSpacing.xl),
            if (_transcript.isNotEmpty && _isListening) ...[
              Text("LIVE TRANSCRIPT", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.sm),
              PitchTranscriptCard(transcript: _transcript),
            ],
            if (_results != null) ...[
              SizedBox(height: AppSpacing.md),
              Text("YOUR RESULTS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: PitchStatCard(value: "${_results!['wpm']}", label: "Words/Min", color: _results!['paceColor'])),
                SizedBox(width: AppSpacing.md),
                Expanded(child: PitchStatCard(value: "${_results!['wordCount']}", label: "Total Words", color: AppColors.info)),
              ]),
              SizedBox(height: AppSpacing.md),
              PitchPaceCard(paceLabel: _results!['paceLabel'], paceColor: _results!['paceColor']),
              SizedBox(height: AppSpacing.md),
              PitchFillerWordsCard(
                totalFillers: _results!['totalFillers'] as int,
                fillerRate: _results!['fillerRate'] as double,
                fillerCounts: Map<String, int>.from(_results!['fillerCounts'] as Map),
              ),
              SizedBox(height: AppSpacing.md),
              Text("FULL TRANSCRIPT", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.sm),
              PitchTranscriptCard(transcript: _transcript),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
