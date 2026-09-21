import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class FraudDefenseScanner extends StatefulWidget {
  const FraudDefenseScanner({super.key});
  @override
  State<FraudDefenseScanner> createState() => _FraudDefenseScannerState();
}

class _FraudDefenseScannerState extends State<FraudDefenseScanner> {
  late Future<List<Map<String, dynamic>>> _flagsFuture;

  @override
  void initState() {
    super.initState();
    _flagsFuture = _runIntegrityCheck();
  }

  Future<List<Map<String, dynamic>>> _runIntegrityCheck() async {
    final client = Supabase.instance.client;

    final apps = await client
        .from('applications')
        .select('id, user_id, job_title, company_name, profiles(full_name, resume_path)');
    final rows = List<Map<String, dynamic>>.from(apps);

    final seen = <String, int>{};
    for (final row in rows) {
      final key = '${row['user_id']}_${row['job_title']}_${row['company_name']}';
      seen[key] = (seen[key] ?? 0) + 1;
    }

    final flagged = <Map<String, dynamic>>[];
    for (final row in rows) {
      final name = row['profiles']?['full_name'] ?? 'Unknown Candidate';
      final resumePath = row['profiles']?['resume_path'];
      final key = '${row['user_id']}_${row['job_title']}_${row['company_name']}';
      final duplicateCount = seen[key] ?? 1;
      final missingResume = (resumePath == null || resumePath.toString().isEmpty);

      if (duplicateCount > 1 || missingResume) {
        flagged.add({
          'name': name,
          'job_title': row['job_title'],
          'company_name': row['company_name'],
          'duplicate_count': duplicateCount,
          'missing_resume': missingResume,
        });
      }
    }

    return flagged;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.topLarge,
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _flagsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final flags = snapshot.data ?? [];

          return Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("APPLICATION INTEGRITY CHECK", style: AppTypography.sectionHeader),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
                SizedBox(height: AppSpacing.xs),
                Text("Flags duplicate applications and missing resumes — no fabricated claims.", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: flags.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.gpp_good, color: AppColors.success, size: 60),
                              SizedBox(height: AppSpacing.md),
                              Text("No integrity issues found", style: AppTypography.bodyMediumBold),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: flags.length,
                          itemBuilder: (context, i) {
                            final f = flags[i];
                            return Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.05),
                                borderRadius: AppBorderRadius.medium,
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f['name'], style: AppTypography.bodyMediumBold),
                                  Text("${f['job_title']} @ ${f['company_name']}", style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                  SizedBox(height: AppSpacing.sm),
                                  if (f['duplicate_count'] > 1)
                                    Row(children: [
                                      Icon(Icons.content_copy, size: 14, color: AppColors.warning),
                                      SizedBox(width: AppSpacing.xs),
                                      Text("Applied ${f['duplicate_count']}x to this same role", style: AppTypography.captionBold.copyWith(color: AppColors.warning)),
                                    ]),
                                  if (f['missing_resume'])
                                    Padding(
                                      padding: EdgeInsets.only(top: AppSpacing.xs),
                                      child: Row(children: [
                                        Icon(Icons.description_outlined, size: 14, color: AppColors.error),
                                        SizedBox(width: AppSpacing.xs),
                                        Text("No resume uploaded", style: AppTypography.captionBold.copyWith(color: AppColors.error)),
                                      ]),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
