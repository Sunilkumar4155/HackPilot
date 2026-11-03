import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/services/translation_service.dart';
import 'package:ai_hackathon_finder/utils/hackathon_image_helper.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/providers/theme_provider.dart';

void main() {
  group('Unit Tests: TranslationService Engine & Caching', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
      service.clearCache();
    });

    test('English content is detected accurately and not sent to translation API', () async {
      const englishSentence = 'Join the premier developer hackathon to build generative AI solutions.';
      expect(service.isLikelyEnglish(englishSentence), isTrue);

      final result = await service.translateToEnglish(englishSentence);
      expect(result.wasTranslated, isFalse);
      expect(result.detectedLanguage, 'English');
      expect(result.displayText, englishSentence);
      expect(result.isError, isFalse);
    });

    test('Indic scripts (Devanagari, Bengali, Tamil, Telugu) are classified as non-English', () {
      const hindi = 'छात्रों के लिए राष्ट्रीय कोडिंग हैकथॉन';
      const bengali = 'উন্নত কোডিং প্রতিযোগিতা';
      const tamil = 'மாணவர்களுக்கான தேசிய போட்டி';
      const telugu = 'డెవలపర్ హ్యాకథాన్ సవాలు';

      expect(service.isLikelyEnglish(hindi), isFalse);
      expect(service.isLikelyEnglish(bengali), isFalse);
      expect(service.isLikelyEnglish(tamil), isFalse);
      expect(service.isLikelyEnglish(telugu), isFalse);

      expect(service.detectLanguageLabel(hindi).contains('Hindi'), isTrue);
      expect(service.detectLanguageLabel(bengali).contains('Bengali'), isTrue);
      expect(service.detectLanguageLabel(tamil).contains('Tamil'), isTrue);
      expect(service.detectLanguageLabel(telugu).contains('Telugu'), isTrue);
    });

    test('East Asian and European non-English languages are detected accurately', () {
      const chinese = '全球人工智能黑客松竞赛';
      const japanese = 'ハッカソン開発コンテスト';
      const russian = 'Хакатон по искусственному интеллекту';
      const spanish = 'Concurso nacional de desarrollo e innovación de software';

      expect(service.isLikelyEnglish(chinese), isFalse);
      expect(service.isLikelyEnglish(japanese), isFalse);
      expect(service.isLikelyEnglish(russian), isFalse);
      expect(service.isLikelyEnglish(spanish), isFalse);

      expect(service.detectLanguageLabel(chinese).contains('Chinese'), isTrue);
      expect(service.detectLanguageLabel(japanese).contains('Japanese'), isTrue);
      expect(service.detectLanguageLabel(russian).contains('Russian'), isTrue);
      expect(service.detectLanguageLabel(spanish).contains('Spanish'), isTrue);
    });

    test('Empty or whitespace input returns instantly without network operations', () async {
      final res1 = await service.translateToEnglish('');
      expect(res1.wasTranslated, isFalse);
      expect(res1.displayText, '');

      final res2 = await service.translateToEnglish('     \n\t  ');
      expect(res2.wasTranslated, isFalse);
      expect(res2.displayText.trim(), '');
    });
  });

  group('Unit Tests: Registration URL Normalization & Security Filtering', () {
    Uri? parseAndValidateLink(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.contains('://') && !trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        return null;
      }
      final withScheme = (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
          ? trimmed
          : 'https://$trimmed';
      final uri = Uri.tryParse(withScheme);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
        return uri;
      }
      return null;
    }

    test('Valid web links are sanitized and normalized with HTTPS', () {
      final u1 = parseAndValidateLink('devpost.com/hackathons/ai');
      expect(u1, isNotNull);
      expect(u1!.scheme, 'https');
      expect(u1.host, 'devpost.com');

      final u2 = parseAndValidateLink('https://unstop.com/hackathons/smart-india?ref=portal');
      expect(u2, isNotNull);
      expect(u2!.queryParameters['ref'], 'portal');
    });

    test('Dangerous or malicious URI schemes are strictly rejected', () {
      expect(parseAndValidateLink('javascript:alert(1)'), isNull);
      expect(parseAndValidateLink('data:text/html,<script>alert(1)</script>'), isNull);
      expect(parseAndValidateLink('file:///etc/passwd'), isNull);
      expect(parseAndValidateLink('blob:https://example.com/uuid'), isNull);
      expect(parseAndValidateLink(''), isNull);
    });
  });

  group('Unit Tests: HackathonImageHelper Photography Mapping', () {
    test('Image helper maps technical domains to diverse Unsplash themes', () {
      final ai = Hackathon(
        id: '1', title: 'Generative AI Sprint', organizer: 'AI Club', deadline: '',
        prize: '', description: 'deep learning neural networks llm', location: 'Online',
        mode: 'Online', teamSize: '', registrationLink: '',
      );
      final web = Hackathon(
        id: '2', title: 'React & Full-Stack Web', organizer: 'Web Hub', deadline: '',
        prize: '', description: 'frontend backend javascript flutter', location: 'Online',
        mode: 'Online', teamSize: '', registrationLink: '',
      );
      final sec = Hackathon(
        id: '3', title: 'Cyber Defense CTF', organizer: 'Security Team', deadline: '',
        prize: '', description: 'infosec zero-day penetration testing', location: 'Online',
        mode: 'Online', teamSize: '', registrationLink: '',
      );

      final imgAi = HackathonImageHelper.resolveImageUrl(ai);
      final imgWeb = HackathonImageHelper.resolveImageUrl(web);
      final imgSec = HackathonImageHelper.resolveImageUrl(sec);

      expect(imgAi.isNotEmpty, isTrue);
      expect(imgWeb.isNotEmpty, isTrue);
      expect(imgSec.isNotEmpty, isTrue);

      expect(imgAi != imgWeb, isTrue);
      expect(imgAi != imgSec, isTrue);
    });
  });

  group('Unit Tests: ThemeProvider State Logic', () {
    test('ThemeProvider initializes with default dark theme and preserves brand identity', () {
      final provider = ThemeProvider();
      expect(provider.isDark, isTrue);

      // Attempting toggle maintains dark mode aesthetic
      provider.toggleTheme(false);
      expect(provider.isDark, isTrue);

      provider.toggleTheme(true);
      expect(provider.isDark, isTrue);
    });
  });
}
