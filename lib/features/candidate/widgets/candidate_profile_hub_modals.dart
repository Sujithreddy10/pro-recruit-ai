import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

String fmtProfileDate(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

Widget buildProfileDatePicker(BuildContext ctx, String label, DateTime? value,
    bool enabled, void Function(DateTime) onPicked) {
  return Opacity(
    opacity: enabled ? 1 : 0.4,
    child: IgnorePointer(
      ignoring: !enabled,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1980),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          );
          if (picked != null) onPicked(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo, size: 18),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: AppBorderRadius.small, borderSide: BorderSide.none),
          ),
          child: Text(value == null ? "Select date" : fmtProfileDate(value)),
        ),
      ),
    ),
  );
}

class ProfileModals {
  static Future<Map<String, dynamic>?> showBasicDetails(
      BuildContext context, Map<String, dynamic> data, String candidateEmail) async {
    final workStatusCtrl = TextEditingController(text: data['work_status'] ?? '');
    final cityCtrl = TextEditingController(text: data['city'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final availabilityCtrl = TextEditingController(text: data['availability'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Edit Basic Details", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              enabled: false,
              controller: TextEditingController(text: candidateEmail),
              decoration: const InputDecoration(labelText: "Email ID (login email)"),
            ),
            TextField(controller: workStatusCtrl, decoration: const InputDecoration(labelText: "Work Status")),
            TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: "Current City")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Mobile Number")),
            TextField(controller: availabilityCtrl, decoration: const InputDecoration(labelText: "Availability to Join")),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save")),
        ],
      ),
    );

    if (result == true) {
      return {
        'work_status': workStatusCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'availability': availabilityCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<String?> showEditSummary(BuildContext context, Map<String, dynamic> data) async {
    final summaryCtrl = TextEditingController(text: data['professional_summary'] ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text("Edit Professional Summary", style: AppTypography.titleMedium),
        content: TextField(
          controller: summaryCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: "Professional Summary",
            hintText: "2-3 sentences about your experience and strengths",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save")),
        ],
      ),
    );

    return result == true ? summaryCtrl.text.trim() : null;
  }

  static Future<Map<String, dynamic>?> showCareerPreferences(
      BuildContext context, Map<String, dynamic> data) async {
    final modes = {'Remote', 'Hybrid', 'On-site'};
    final selectedModes = (data['preferred_work_mode'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final locations = (data['preferred_location'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final salaryCtrl = TextEditingController(text: data['expected_salary'] ?? '');
    final locationCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Edit Career Preferences", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Work Mode", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: modes.map((m) {
                    final selected = selectedModes.contains(m);
                    return FilterChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (v) => setDialogState(() {
                        if (v) {
                          selectedModes.add(m);
                        } else {
                          selectedModes.remove(m);
                        }
                      }),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.md),
                Text("Preferred Locations", style: AppTypography.bodySmallBold),
                SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: "Add a city"),
                      onSubmitted: (v) {
                        final city = v.trim();
                        if (city.isNotEmpty && !locations.contains(city)) {
                          setDialogState(() {
                            locations.add(city);
                            locationCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      final city = locationCtrl.text.trim();
                      if (city.isNotEmpty && !locations.contains(city)) {
                        setDialogState(() {
                          locations.add(city);
                          locationCtrl.clear();
                        });
                      }
                    },
                  ),
                ]),
                SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: locations
                      .map((city) => Chip(
                            label: Text(city),
                            onDeleted: () => setDialogState(() => locations.remove(city)),
                          ))
                      .toList(),
                ),
                SizedBox(height: AppSpacing.md),
                TextField(
                  controller: salaryCtrl,
                  decoration: const InputDecoration(labelText: "Expected Salary (e.g. 30LPA+)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Save")),
          ],
        ),
      ),
    );

    if (result == true) {
      return {
        'preferred_work_mode': selectedModes.join(', '),
        'preferred_location': locations.join(', '),
        'expected_salary': salaryCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddOrEditSkill(
      BuildContext context, {Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['skill_name'] ?? '');
    final categoryCtrl = TextEditingController(text: item?['category'] ?? '');
    String proficiency = item?['proficiency'] ?? 'Beginner';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text(item == null ? "Add Skill" : "Edit Skill", style: AppTypography.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Skill Name (e.g. FastAPI)"),
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: "Category (e.g. REST API Development)"),
              ),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: proficiency,
                decoration: const InputDecoration(labelText: "Proficiency"),
                items: ['Beginner', 'Pro', 'Advanced']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => proficiency = v ?? 'Beginner'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(item == null ? "Add" : "Save")),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      return {
        'skill_name': nameCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'proficiency': proficiency,
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddOrEditProject(
      BuildContext context, {Map<String, dynamic>? item}) async {
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final tagsCtrl = TextEditingController(text: item?['tech_tags'] ?? '');
    final linkCtrl = TextEditingController(text: item?['project_link'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text(item == null ? "Add Project" : "Edit Project", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Project Title")),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: "Tech Tags (comma separated)")),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: "Project Link (optional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(item == null ? "Add" : "Save")),
        ],
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      return {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'tech_tags': tagsCtrl.text.trim(),
        'project_link': linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddOrEditEmployment(
      BuildContext context, {Map<String, dynamic>? item}) async {
    final companyCtrl = TextEditingController(text: item?['company_name'] ?? '');
    final designationCtrl = TextEditingController(text: item?['designation'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    bool isCurrent = item?['is_current'] == true;
    DateTime? startDate = item?['start_date'] != null ? DateTime.tryParse(item!['start_date']) : null;
    DateTime? endDate = item?['end_date'] != null ? DateTime.tryParse(item!['end_date']) : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text(item == null ? "Add Employment" : "Edit Employment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name")),
              TextField(controller: designationCtrl, decoration: const InputDecoration(labelText: "Designation")),
              SizedBox(height: AppSpacing.md),
              buildProfileDatePicker(ctx, "Start Date", startDate, true, (d) => setDialogState(() => startDate = d)),
              SizedBox(height: AppSpacing.md),
              buildProfileDatePicker(ctx, "End Date", endDate, !isCurrent, (d) => setDialogState(() => endDate = d)),
              CheckboxListTile(
                value: isCurrent,
                title: const Text("I currently work here"),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
              ),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(item == null ? "Add" : "Save")),
          ],
        ),
      ),
    );

    if (result == true && companyCtrl.text.trim().isNotEmpty) {
      return {
        'company_name': companyCtrl.text.trim(),
        'designation': designationCtrl.text.trim(),
        'start_date': startDate != null ? fmtProfileDate(startDate!) : null,
        'end_date': isCurrent ? null : (endDate != null ? fmtProfileDate(endDate!) : null),
        'is_current': isCurrent,
        'description': descCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddOrEditEducation(
      BuildContext context, {Map<String, dynamic>? item}) async {
    final degreeCtrl = TextEditingController(text: item?['degree'] ?? '');
    final institutionCtrl = TextEditingController(text: item?['institution'] ?? '');
    final yearCtrl = TextEditingController(text: item?['year_of_passing']?.toString() ?? '');
    final gradeCtrl = TextEditingController(text: item?['grade'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        title: Text(item == null ? "Add Education" : "Edit Education", style: AppTypography.titleMedium),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: degreeCtrl, decoration: const InputDecoration(labelText: "Degree (e.g. B.Tech Computer Science)")),
            TextField(controller: institutionCtrl, decoration: const InputDecoration(labelText: "Institution")),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: "Year of Passing")),
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: "Grade / CGPA (optional)")),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(item == null ? "Add" : "Save")),
        ],
      ),
    );

    if (result == true && degreeCtrl.text.trim().isNotEmpty) {
      return {
        'degree': degreeCtrl.text.trim(),
        'institution': institutionCtrl.text.trim(),
        'year_of_passing': yearCtrl.text.trim(),
        'grade': gradeCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddOrEditAccomplishment(
      BuildContext context, {Map<String, dynamic>? item}) async {
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final dateCtrl = TextEditingController(text: item?['date_achieved'] ?? '');
    String type = item?['type'] ?? 'Award';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text(item == null ? "Add Accomplishment" : "Edit Accomplishment", style: AppTypography.titleMedium),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: "Type"),
                items: ['Award', 'Certification', 'Achievement']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v ?? 'Award'),
              ),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date (e.g. Mar 2024)")),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Description (optional)")),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(item == null ? "Add" : "Save")),
          ],
        ),
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      return {
        'title': titleCtrl.text.trim(),
        'type': type,
        'description': descCtrl.text.trim(),
        'date_achieved': dateCtrl.text.trim(),
      };
    }
    return null;
  }

  static Future<Map<String, dynamic>?> showAddLanguage(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String proficiency = 'Beginner';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
          title: Text("Add Language", style: AppTypography.titleMedium),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Language (e.g. English)")),
            SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: proficiency,
              decoration: const InputDecoration(labelText: "Proficiency"),
              items: ['Beginner', 'Advanced', 'Pro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setDialogState(() => proficiency = v ?? 'Beginner'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add")),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      return {
        'language_name': nameCtrl.text.trim(),
        'proficiency': proficiency,
      };
    }
    return null;
  }
}
