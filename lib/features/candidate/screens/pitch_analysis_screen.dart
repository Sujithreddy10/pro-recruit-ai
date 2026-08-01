import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pro_recruit_ai/shared/app_design_system.dart';

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

    _speech.listen(
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    final words = _transcript.trim().isEmpty
        ? <String>[]
        : _transcript.trim().split(RegExp(r'\s+'));
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
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF7F1D1D), AppColors.error]),
              borderRadius: AppBorderRadius.large,
              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REAL-TIME SPEECH ANALYSIS", style: AppTypography.sectionHeader.copyWith(color: Colors.red.shade100, letterSpacing: 1.6)),
                SizedBox(height: AppSpacing.xs),
                Text("Speak your pitch out loud", style: AppTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 16)),
                Text("Real pace and filler-word tracking \u2014 no fabricated scores.",
                    style: AppTypography.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          if (!_speechAvailable)
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card(),
              child: Text("Speech recognition isn't available on this device, or microphone permission was denied.",
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
            )
          else ...[
            Center(
              child: Column(
                children: [
                  Text(_formatDuration(_elapsedSeconds), style: AppTypography.headlineLarge.copyWith(fontSize: 32)),
                  SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: _isListening
                            ? [AppColors.error, const Color(0xFF7F1D1D)]
                            : [AppColors.success, const Color(0xFF064E3B)]),
                        boxShadow: [
                          BoxShadow(
                              color: (_isListening ? AppColors.error : AppColors.success).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(_isListening ? "Listening... tap to stop" : "Tap to start speaking",
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            if (_transcript.isNotEmpty && _isListening) ...[
              Text("LIVE TRANSCRIPT", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.sm),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(),
                child: Text(_transcript, style: AppTypography.bodyMedium),
              ),
            ],
            if (_results != null) ...[
              SizedBox(height: AppSpacing.md),
              Text("YOUR RESULTS", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: _statCard("${_results!['wpm']}", "Words/Min", _results!['paceColor'])),
                SizedBox(width: AppSpacing.md),
                Expanded(child: _statCard("${_results!['wordCount']}", "Total Words", AppColors.info)),
              ]),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(),
                child: Row(children: [
                  Icon(Icons.speed, color: _results!['paceColor']),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_results!['paceLabel'], style: AppTypography.bodyMediumBold.copyWith(color: _results!['paceColor'])),
                        Text("Ideal conversational pace is 110\u2013160 words per minute.",
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ]),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.record_voice_over, color: AppColors.warning),
                      SizedBox(width: AppSpacing.sm),
                      Text("Filler Words: ${_results!['totalFillers']}", style: AppTypography.bodyMediumBold),
                    ]),
                    SizedBox(height: AppSpacing.xs),
                    Text("${_results!['fillerRate'].toStringAsFixed(1)}% of your words were fillers",
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    if ((_results!['fillerCounts'] as Map).isNotEmpty) ...[
                      SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: (_results!['fillerCounts'] as Map<String, int>)
                            .entries
                            .map((e) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: AppDecorations.pill(AppColors.warning),
                                  child: Text('"${e.key}" x${e.value}',
                                      style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text("FULL TRANSCRIPT", style: AppTypography.sectionHeader),
              SizedBox(height: AppSpacing.sm),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(),
                child: Text(_transcript.isEmpty ? "No speech detected." : _transcript, style: AppTypography.bodyMedium),
              ),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.headlineLarge.copyWith(color: color, fontSize: 24)),
            SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
}
