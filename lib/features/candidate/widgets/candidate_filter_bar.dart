import 'package:flutter/material.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';

class CandidateFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final Set<String> selectedLocations;
  final Set<String> selectedWorkModes;
  final VoidCallback onFiltersChanged;

  const CandidateFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.selectedLocations,
    required this.selectedWorkModes,
    required this.onFiltersChanged,
  });

  void _showFilterSheet(BuildContext context, String title, List<String> options, Set<String> selected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => StatefulBuilder(
        builder: (c, setSheetState) => Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setSheetState(() => selected.clear());
                        onFiltersChanged();
                      },
                      child: const Text("Clear"),
                    ),
                ],
              ),
              const Divider(),
              Wrap(
                spacing: AppSpacing.sm,
                children: options
                    .map((o) => FilterChip(
                          label: Text(o, style: const TextStyle(color: Colors.black87)),
                          selected: selected.contains(o),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          onSelected: (v) {
                            setSheetState(() {
                              if (v) {
                                selected.add(o);
                              } else {
                                selected.remove(o);
                              }
                            });
                            onFiltersChanged();
                          },
                        ))
                    .toList(),
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, List<String> options, Set<String> selected) => ActionChip(
        label: Text(
          selected.isEmpty ? label : "$label (${selected.length})",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 11),
        ),
        onPressed: () => _showFilterSheet(context, label, options, selected),
        avatar: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black54),
        backgroundColor: selected.isEmpty ? Colors.white : AppColors.primary.withValues(alpha: 0.15),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10)],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search Roles...",
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                context,
                "Locations",
                ["Hyderabad", "Chennai", "Bengaluru", "Kolkata", "Delhi", "Pune", "Gurgaon"],
                selectedLocations,
              ),
              SizedBox(width: AppSpacing.sm),
              _filterChip(
                context,
                "Work Mode",
                ["Hybrid", "Remote", "On-site"],
                selectedWorkModes,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
