import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CandidateSearchService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> searchCandidates(String rawQuery) async {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return [];

    // Prefix match for partial words ('java' -> 'java:*')
    final formattedQuery = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => "$w:*")
        .join(' & ');

    debugPrint("CandidateSearchService query: '$formattedQuery' (raw: '$trimmed')");

    try {
      final response = await _client
          .from('profiles')
          .select()
          .textSearch('fts_resume', formattedQuery, config: 'english')
          .limit(30);

      debugPrint("Postgres FTS returned: ${response.length} profiles");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Postgres FTS query failed: $e, executing fallback ilike search");
      try {
        final fallback = await _client
            .from('profiles')
            .select()
            .or('role.ilike.%$trimmed%,full_name.ilike.%$trimmed%')
            .limit(30);

        debugPrint("Fallback ilike returned: ${fallback.length} profiles");
        return List<Map<String, dynamic>>.from(fallback);
      } catch (fallbackError) {
        debugPrint("Fallback ilike also failed: $fallbackError");
        return [];
      }
    }
  }
}
