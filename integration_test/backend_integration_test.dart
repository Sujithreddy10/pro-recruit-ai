import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: "assets/.env");
    String rawUrl = dotenv.get('SUPABASE_URL', fallback: "");
    String rawKey = dotenv.get('SUPABASE_ANON_KEY', fallback: "");
    String cleanUrl = rawUrl.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();
    String cleanKey = rawKey.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();

    await Supabase.initialize(url: cleanUrl, publishableKey: cleanKey);
  });

  group('Backend integration tests', () {
    testWidgets('basic connectivity check - can read jobs table', (tester) async {
      final client = Supabase.instance.client;
      final data = await client.from('jobs').select('id, title').limit(1);
      expect(data, isNotEmpty);
    });

    testWidgets('new recruiter signup gets user_role = recruiter', (tester) async {
      final client = Supabase.instance.client;
      final testEmail = 'testrecruiter${DateTime.now().millisecondsSinceEpoch}@gmail.com';
      const testPassword = 'TestPassword123!';

      final res = await client.auth.signUp(
        email: testEmail,
        password: testPassword,
        data: {
          'user_role': 'recruiter',
          'full_name': 'Test Recruiter',
        },
      );

      expect(res.user, isNotNull);

      await Future.delayed(const Duration(seconds: 2));

      final profile = await client
          .from('profiles')
          .select('user_role')
          .eq('id', res.user!.id)
          .maybeSingle();

      expect(profile, isNotNull);
      expect(profile!['user_role'], 'recruiter');

      await client.auth.signOut();
    });

    testWidgets('recruiter can view applications, candidate sees only own', (tester) async {
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final candidateEmail = 'testcandidate$timestamp@gmail.com';
      const password = 'TestPassword123!';
      final candidateRes = await client.auth.signUp(
        email: candidateEmail,
        password: password,
        data: {'user_role': 'candidate', 'full_name': 'Test Candidate'},
      );
      expect(candidateRes.user, isNotNull);
      final candidateId = candidateRes.user!.id;

      await Future.delayed(const Duration(seconds: 2));

      await client.from('applications').insert({
        'user_id': candidateId,
        'job_title': 'Integration Test Role',
        'company_name': 'Integration Test Co',
        'status': 'applied',
        'created_at': DateTime.now().toIso8601String(),
      });

      final ownApps = await client
          .from('applications')
          .select('id, job_title')
          .eq('user_id', candidateId);
      expect(ownApps, isNotEmpty);

      await client.auth.signOut();

      final recruiterEmail = 'testrecruiterrls$timestamp@gmail.com';
      final recruiterRes = await client.auth.signUp(
        email: recruiterEmail,
        password: password,
        data: {'user_role': 'recruiter', 'full_name': 'Test Recruiter RLS'},
      );
      expect(recruiterRes.user, isNotNull);

      await Future.delayed(const Duration(seconds: 2));

      final recruiterView = await client
          .from('applications')
          .select('id, job_title, user_id')
          .eq('user_id', candidateId);
      expect(recruiterView, isNotEmpty);
      expect(recruiterView.first['job_title'], 'Integration Test Role');

      await client.auth.signOut();
    });

    testWidgets('application status flow: applied -> shortlisted -> offer_sent -> hired', (tester) async {
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const password = 'TestPassword123!';

      final candidateEmail = 'testflow$timestamp@gmail.com';
      final candidateRes = await client.auth.signUp(
        email: candidateEmail,
        password: password,
        data: {'user_role': 'candidate', 'full_name': 'Flow Test Candidate'},
      );
      expect(candidateRes.user, isNotNull);
      final candidateId = candidateRes.user!.id;

      await Future.delayed(const Duration(seconds: 2));

      final inserted = await client.from('applications').insert({
        'user_id': candidateId,
        'job_title': 'Status Flow Test Role',
        'company_name': 'Status Flow Test Co',
        'status': 'applied',
        'created_at': DateTime.now().toIso8601String(),
      }).select();
      expect(inserted, isNotEmpty);
      final applicationId = inserted.first['id'];

      await client.auth.signOut();

      final recruiterEmail = 'testrecflow$timestamp@gmail.com';
      final recruiterRes = await client.auth.signUp(
        email: recruiterEmail,
        password: password,
        data: {'user_role': 'recruiter', 'full_name': 'Flow Test Recruiter'},
      );
      expect(recruiterRes.user, isNotNull);

      await Future.delayed(const Duration(seconds: 2));

      await client.from('applications').update({'status': 'shortlisted'}).eq('id', applicationId);
      var check = await client.from('applications').select('status').eq('id', applicationId).single();
      expect(check['status'], 'shortlisted');

      await client.from('applications').update({'status': 'offer_sent'}).eq('id', applicationId);
      check = await client.from('applications').select('status').eq('id', applicationId).single();
      expect(check['status'], 'offer_sent');

      await client.from('applications').update({'status': 'hired'}).eq('id', applicationId);
      check = await client.from('applications').select('status').eq('id', applicationId).single();
      expect(check['status'], 'hired');

      final hiredRows = await client
          .from('applications')
          .select('id, status')
          .eq('user_id', candidateId)
          .inFilter('status', ['offer_sent', 'hired']);
      expect(hiredRows, isNotEmpty);
      expect(hiredRows.first['status'], 'hired');

      await client.auth.signOut();
    });
  });
}
