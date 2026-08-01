import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    await dotenv.load(fileName: "assets/.env");
    String rawUrl = dotenv.get('SUPABASE_URL', fallback: "");
    String rawKey = dotenv.get('SUPABASE_ANON_KEY', fallback: "");
    String cleanUrl = rawUrl.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();
    String cleanKey = rawKey.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();

    print('===== TEST DEBUG START =====');
    print('URL LENGTH: ${cleanUrl.length}');
    print('URL VALUE: "$cleanUrl"');
    print('KEY LENGTH: ${cleanKey.length}');
    print('KEY VALUE (first 20 chars): "${cleanKey.substring(0, 20)}"');
    print('KEY VALUE (last 20 chars): "${cleanKey.substring(cleanKey.length - 20)}"');
    print('===== TEST DEBUG END =====');

    await Supabase.initialize(url: cleanUrl, publishableKey: cleanKey);
  });

  test('basic connectivity check - can read jobs table', () async {
    final client = Supabase.instance.client;
    final data = await client.from('jobs').select('id, title').limit(1);
    print('CONNECTIVITY TEST RESULT: $data');
    expect(data, isNotEmpty);
  });
}