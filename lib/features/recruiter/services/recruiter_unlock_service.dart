import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecruiterUnlockService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Global notifier so AppBar pills and modals update reactively on deduction
  static final ValueNotifier<int?> creditBalanceNotifier = ValueNotifier<int?>(null);

  /// Check whether the current recruiter has already unlocked this candidate
  static Future<bool> isCandidateUnlocked(String candidateId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await _client
          .from('recruiter_unlocks')
          .select('id')
          .eq('recruiter_id', user.id)
          .eq('candidate_id', candidateId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint("Error checking candidate unlock status: $e");
      return false;
    }
  }

  /// Get current recruiter credit balance
  static Future<int> getRecruiterCredits() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final res = await _client
          .from('profiles')
          .select('credits')
          .eq('id', user.id)
          .maybeSingle();

      final credits = (res?['credits'] as int?) ?? 10;
      creditBalanceNotifier.value = credits;
      return credits;
    } catch (e) {
      debugPrint("Error fetching recruiter credits: $e");
      return creditBalanceNotifier.value ?? 10;
    }
  }

  /// Unlock candidate profile: validates balance first, deducts credit, then records unlock
  static Future<bool> unlockCandidate(String candidateId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Guard check: already unlocked?
      final alreadyUnlocked = await isCandidateUnlocked(candidateId);
      if (alreadyUnlocked) return true;

      // 2. Guard check: balance sufficient?
      final currentCredits = await getRecruiterCredits();
      if (currentCredits <= 0) {
        debugPrint("Unlock rejected: insufficient recruiter credits ($currentCredits)");
        return false;
      }

      // 3. Deduct credit
      final updatedCredits = currentCredits - 1;
      await _client
          .from('profiles')
          .update({'credits': updatedCredits})
          .eq('id', user.id);

      // 4. Record unlock log
      await _client.from('recruiter_unlocks').insert({
        'recruiter_id': user.id,
        'candidate_id': candidateId,
      });

      // 5. Broadcast new balance to UI listeners
      creditBalanceNotifier.value = updatedCredits;
      return true;
    } catch (e) {
      debugPrint("Error unlocking candidate: $e");
      return false;
    }
  }
}
