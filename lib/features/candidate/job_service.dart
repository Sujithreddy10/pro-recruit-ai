// lib/features/candidate/job_service.dart
class JobService {
  // Simulating a database fetch
  static Future<List<Map<String, String>>> fetchJobs() async {
    await Future.delayed(const Duration(seconds: 1)); // Network lag simulation
    return [
      {"t": "Senior Flutter Lead", "c": "T-Hub Hyderabad", "m": "Hybrid", "d": "Lead Flutter dev for high-scale enterprise."},
      {"t": "Senior Flutter Architect", "c": "Google Bengaluru", "m": "On-site", "d": "Architecting next-gen cross-platform frameworks."},
      {"t": "Flutter Engineer", "c": "Amazon Hyderabad", "m": "Remote", "d": "Scale Amazon retail apps using Flutter."},
    ];
  }
}