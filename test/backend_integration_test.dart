// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  test('jobs endpoint connectivity and live data validation', () async {
    await dotenv.load(fileName: "assets/.env");

    final rawUrl = dotenv.maybeGet('SUPABASE_URL') ?? "";
    final rawKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? "";
    final cleanUrl = rawUrl.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();
    final cleanKey = rawKey.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();

    expect(cleanUrl.isNotEmpty, isTrue);
    expect(cleanKey.isNotEmpty, isTrue);

    final uri = Uri.parse('$cleanUrl/rest/v1/jobs?select=id,title,company,salary_range&limit=5');
    final response = await http.get(uri, headers: {
      'apikey': cleanKey,
      'Authorization': 'Bearer $cleanKey',
    });

    expect(response.statusCode, equals(200));
    final data = jsonDecode(response.body) as List;
    expect(data.isNotEmpty, isTrue);
    print('Verified: Fetched ${data.length} live jobs from Supabase with status ${response.statusCode}!');
  });
}
