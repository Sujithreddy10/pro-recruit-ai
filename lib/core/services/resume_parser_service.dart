import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResumeParserService {
  /// Extracts text and detects tech stack markers directly on-device.
  static Future<Map<String, dynamic>> parseLocalResume(File pdfFile) async {
    try {
      final List<int> bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String fullText = PdfTextExtractor(document).extractText();
      document.dispose();

      // 1. Extract phone number before scrubbing
      String? extractedPhone;
      final phoneMatch = RegExp(r'\b(?:\+91[\-\s]?)?[6-9]\d{9}\b').firstMatch(fullText);
      if (phoneMatch != null) {
        final raw = phoneMatch.group(0) ?? '';
        var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length > 10 && digits.startsWith('91')) {
          digits = digits.substring(2);
        }
        if (digits.length == 10) {
          extractedPhone = digits;
        }
      }

      // 2. Scrub PII locally so phone numbers and emails are masked
      final scrubbedText = fullText
          .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b'), '[PROTECTED_EMAIL]')
          .replaceAll(RegExp(r'\b(?:\+91|0)?[6-9]\d{9}\b'), '[PROTECTED_PHONE]');

      // 3. Client-side heuristic matching (Zero-cost filtering)
      final List<String> detectedSkills = [];
      const keywords = [
        'Flutter', 'Dart', 'Python', 'FastAPI', 'SQL',
        'PostgreSQL', 'React', 'Node.js', 'Git', 'Docker'
      ];

      final lowerText = fullText.toLowerCase();
      for (final skill in keywords) {
        if (lowerText.contains(skill.toLowerCase())) {
          detectedSkills.add(skill);
        }
      }

      return {
        'clean_text': scrubbedText,
        'detected_skills': detectedSkills,
        'extracted_phone': extractedPhone,
        'success': true,
      };
    } catch (e) {
      return {
        'clean_text': '',
        'detected_skills': <String>[],
        'extracted_phone': null,
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
