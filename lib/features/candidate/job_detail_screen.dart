import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, String> job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Job Details")),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(job['t']!, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(job['c']!, style: const TextStyle(fontSize: 18, color: Colors.blue)),
        const SizedBox(height: 20),
        // 🎯 AI MATCH SCORE COMPONENT
        _buildMatchScore(85), 
        const SizedBox(height: 20),
        const Text("Job Description", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(job['d']!),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: () {}, child: const Text("Apply Now"))
      ]),
    );
  }

  Widget _buildMatchScore(int score) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.psychology, color: Colors.green),
      const SizedBox(width: 10),
      Text("AI Match Score: $score%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
    ]),
  );
}