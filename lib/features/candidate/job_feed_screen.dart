import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  // This list will eventually be populated by your Supabase database
  final List<Map<String, String>> _jobs = [
    {"t": "Senior Flutter Lead", "c": "T-Hub", "m": "Hybrid", "d": "Lead Flutter dev for high-scale enterprise."},
    {"t": "Senior Flutter Architect", "c": "Google", "m": "On-site", "d": "Architecting next-gen frameworks."},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Job Feed", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(job['t']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${job['c']} • ${job['m']}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Here is where you will add your navigation to Job Details
              },
            ),
          );
        },
      ),
    );
  }
}