import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class OfferNegotiatorScreen extends StatefulWidget {
  const OfferNegotiatorScreen({super.key});
  @override
  State<OfferNegotiatorScreen> createState() => _OfferNegotiatorScreenState();
}

class _OfferNegotiatorScreenState extends State<OfferNegotiatorScreen> {
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController();
  final TextEditingController _offeredCtrl = TextEditingController();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _experienceCtrl = TextEditingController();
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

  bool get _canSubmit =>
      _companyCtrl.text.trim().isNotEmpty && _roleCtrl.text.trim().isNotEmpty && _offeredCtrl.text.trim().isNotEmpty;

  Future<void> _analyze() async {
    if (!_canSubmit) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'offer-negotiator',
        body: {
          'companyName': _companyCtrl.text.trim(),
          'roleTitle': _roleCtrl.text.trim(),
          'offeredSalary': _offeredCtrl.text.trim(),
          'currentSalary': _currentCtrl.text.trim(),
          'experienceYears': _experienceCtrl.text.trim(),
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
    _companyCtrl.dispose();
    _roleCtrl.dispose();
    _offeredCtrl.dispose();
    _currentCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("Offer Negotiator", style: AppTypography.titleMedium.copyWith(color: Colors.teal)),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.lg),
          children: [
            Text("Get an honest read on your offer, plus talking points and a draft negotiation email.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.lg),
            TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: "Company"), onChanged: (_) => setState(() {})),
            SizedBox(height: AppSpacing.md),
            TextField(controller: _roleCtrl, decoration: const InputDecoration(labelText: "Role / Job Title"), onChanged: (_) => setState(() {})),
            SizedBox(height: AppSpacing.md),
            TextField(controller: _offeredCtrl, decoration: const InputDecoration(labelText: "Offered Salary / CTC"), onChanged: (_) => setState(() {})),
            SizedBox(height: AppSpacing.md),
            TextField(controller: _currentCtrl, decoration: const InputDecoration(labelText: "Current Salary (optional)")),
            SizedBox(height: AppSpacing.md),
            TextField(controller: _experienceCtrl, decoration: const InputDecoration(labelText: "Years of Experience (optional)")),
            SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.error), maxLines: 3, overflow: TextOverflow.ellipsis),
              SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton(
              onPressed: (!_canSubmit || _isLoading) ? null : _analyze,
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Analyze My Offer"),
            ),
            if (_result != null) ...[
              SizedBox(height: AppSpacing.xl),
              Text("Assessment", style: AppTypography.sectionHeader.copyWith(color: Colors.teal)),
              SizedBox(height: AppSpacing.sm),
              Text(_result!['assessment'] as String? ?? '', style: AppTypography.bodyMedium),
              SizedBox(height: AppSpacing.xl),
              Text("Talking Points", style: AppTypography.sectionHeader.copyWith(color: Colors.teal)),
              SizedBox(height: AppSpacing.sm),
              ...List<String>.from(_result!['talkingPoints'] ?? []).map((t) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text("- $t", style: AppTypography.bodyMedium),
                  )),
              SizedBox(height: AppSpacing.xl),
              Text("Draft Negotiation Email", style: AppTypography.sectionHeader.copyWith(color: Colors.teal)),
              SizedBox(height: AppSpacing.sm),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(),
                child: Text(_result!['draftEmail'] as String? ?? '', style: AppTypography.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
