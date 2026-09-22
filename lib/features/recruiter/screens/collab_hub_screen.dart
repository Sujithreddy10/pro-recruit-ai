import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/features/recruiter/widgets/collab_hub_widgets.dart';

class CollabHubScreen extends StatefulWidget {
  const CollabHubScreen({super.key});
  @override
  State<CollabHubScreen> createState() => _CollabHubScreenState();
}

class _CollabHubScreenState extends State<CollabHubScreen> {
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _fetchApplicationsWithNoteCounts();
  }

  void _refresh() {
    setState(() {
      _applicationsFuture = _fetchApplicationsWithNoteCounts();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchApplicationsWithNoteCounts() async {
    final apps = await Supabase.instance.client
        .from('applications')
        .select('id, job_title, company_name, status, profiles(full_name)')
        .order('created_at', ascending: false);
    final appRows = List<Map<String, dynamic>>.from(apps);

    final notes = await Supabase.instance.client.from('candidate_notes').select('application_id');
    final noteRows = List<Map<String, dynamic>>.from(notes);

    final counts = <dynamic, int>{};
    for (final n in noteRows) {
      final appId = n['application_id'];
      counts[appId] = (counts[appId] ?? 0) + 1;
    }

    return appRows.map((a) {
      return {
        ...a,
        'note_count': counts[a['id']] ?? 0,
      };
    }).toList();
  }

  Future<void> _openNotesThread(Map<String, dynamic> application) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.topLarge),
      builder: (ctx) => CollabNotesSheet(application: application),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text("Collab Hub", style: AppTypography.titleMedium.copyWith(color: Colors.deepPurple)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppTypography.bodyMedium));
          }
          final apps = snapshot.data ?? [];
          final filtered = apps.where((a) {
            final name = (a['profiles']?['full_name'] ?? '').toString().toLowerCase();
            final job = (a['job_title'] ?? '').toString().toLowerCase();
            final company = (a['company_name'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || job.contains(q) || company.contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: const CollabHubHeader(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(30)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: "Search candidates, roles...",
                      prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text("No candidates found.", style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final a = filtered[i];
                          return CollabCandidateCard(
                            candidateName: (a['profiles']?['full_name'] ?? 'Candidate').toString(),
                            jobTitle: (a['job_title'] ?? 'N/A').toString(),
                            companyName: (a['company_name'] ?? 'N/A').toString(),
                            noteCount: a['note_count'] as int,
                            onTap: () => _openNotesThread(a),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
