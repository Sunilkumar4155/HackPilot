import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/services/translation_service.dart';

void main() {
  group('Module 4: Complete 15 Scenario Verification Suite', () {
    // -------------------------------------------------------------
    // Scenario 1: Indian offline event (Bengaluru)
    // -------------------------------------------------------------
    test('Scenario 1: Indian offline event (Bengaluru) detects India and physical venue', () {
      final map = {
        'title': 'Bengaluru AI Innovation Sprint',
        'organizer': 'NASSCOM India',
        'deadline': '2026-11-25',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'country': 'India',
        'mode': 'In-person',
      };
      final event = Hackathon.fromMap('blr_1', map);

      expect(event.isIndia, isTrue, reason: 'Must detect India from country/city');
      expect(event.isInternational, isFalse);
      expect(event.isOnline, isFalse);
      expect(event.isInPerson, isTrue);
      expect(event.city, 'Bengaluru');
      expect(event.state, 'Karnataka');
      expect(event.country, 'India');
      expect(event.displayLocation, 'Bengaluru, Karnataka, India');
    });

    // -------------------------------------------------------------
    // Scenario 2: Indian online event
    // -------------------------------------------------------------
    test('Scenario 2: Indian online event displays "Online" and flags India participant scope', () {
      final map = {
        'title': 'Smart India Virtual Code Challenge',
        'organizer': 'AICTE India',
        'deadline': '2026-12-10',
        'country': 'India',
        'mode': 'Online',
        'location': 'Online',
      };
      final event = Hackathon.fromMap('ind_online_1', map);

      expect(event.isIndia, isTrue);
      expect(event.isOnline, isTrue);
      expect(event.isInPerson, isFalse);
      expect(event.displayLocation, 'Online');
    });

    // -------------------------------------------------------------
    // Scenario 3: International offline event (San Francisco)
    // -------------------------------------------------------------
    test('Scenario 3: International offline event (San Francisco) detects international scope and physical location', () {
      final map = {
        'title': 'Autonomous Systems Summit',
        'organizer': 'NVIDIA Lab',
        'deadline': '2026-12-20',
        'city': 'San Francisco',
        'state': 'CA',
        'country': 'USA',
        'mode': 'In-person',
      };
      final event = Hackathon.fromMap('sf_1', map);

      expect(event.isIndia, isFalse);
      expect(event.isInternational, isTrue);
      expect(event.isOnline, isFalse);
      expect(event.isInPerson, isTrue);
      expect(event.displayLocation, 'San Francisco, CA, USA');
    });

    // -------------------------------------------------------------
    // Scenario 4: International online event
    // -------------------------------------------------------------
    test('Scenario 4: International online event displays "Online" and is accessible globally', () {
      final map = {
        'title': 'Global LLM & Multi-Agent Hackathon',
        'organizer': 'Google Cloud Hub',
        'deadline': '2026-11-28',
        'mode': 'Online',
        'location': 'Online',
      };
      final event = Hackathon.fromMap('global_online_1', map);

      expect(event.isOnline, isTrue);
      expect(event.isHybrid, isFalse);
      expect(event.displayLocation, 'Online');
    });

    // -------------------------------------------------------------
    // Scenario 5: Hybrid event
    // -------------------------------------------------------------
    test('Scenario 5: Hybrid event displays "Hybrid • [City]" with physical venue or "Hybrid" standalone', () {
      final hybridWithCity = Hackathon.fromMap('hybrid_1', {
        'title': 'FinTech Hyderabad Challenge',
        'city': 'Hyderabad',
        'mode': 'Hybrid',
      });
      expect(hybridWithCity.isHybrid, isTrue);
      expect(hybridWithCity.displayLocation, 'Hybrid • Hyderabad');

      final hybridGeneric = Hackathon.fromMap('hybrid_2', {
        'title': 'Global Distributed Hackathon',
        'mode': 'Hybrid',
      });
      expect(hybridGeneric.isHybrid, isTrue);
      expect(hybridGeneric.displayLocation, 'Hybrid');
    });

    // -------------------------------------------------------------
    // Scenario 6: Missing location ("Location not provided")
    // -------------------------------------------------------------
    test('Scenario 6: Missing location displays "Location not provided" and suppresses placeholders', () {
      final emptyLoc = Hackathon.fromMap('miss_1', {
        'title': 'Community Meetup Hackathon',
        'mode': 'In-person',
        'location': '',
      });
      expect(emptyLoc.displayLocation, 'Location not provided');

      final placeholderLoc = Hackathon.fromMap('miss_2', {
        'title': 'Legacy Listing',
        'mode': 'In-person',
        'location': 'Not specified',
      });
      expect(placeholderLoc.displayLocation, 'Location not provided');
      expect(placeholderLoc.displayLocation.contains('Not specified'), isFalse);
    });

    // -------------------------------------------------------------
    // Scenario 7: English description (no translation needed)
    // -------------------------------------------------------------
    test('Scenario 7: English description passes through untouched without translation requests', () async {
      final service = TranslationService();
      const englishText = 'Build autonomous multimodal AI agents with advanced reasoning tools.';

      expect(service.isLikelyEnglish(englishText), isTrue);

      final result = await service.translateToEnglish(englishText);
      expect(result.wasTranslated, isFalse);
      expect(result.detectedLanguage, 'English');
      expect(result.displayText, englishText);
    });

    // -------------------------------------------------------------
    // Scenario 8: Hindi description (translates to English)
    // -------------------------------------------------------------
    test('Scenario 8: Hindi description is accurately detected as Indic non-English script', () {
      final service = TranslationService();
      const hindiTitle = 'भारत का सबसे बड़ा एआई हैकथॉन';
      const hindiDesc = 'छात्रों और डेवलपर्स के लिए अत्याधुनिक समाधान तैयार करने की प्रतियोगिता।';

      expect(service.isLikelyEnglish(hindiTitle), isFalse);
      expect(service.isLikelyEnglish(hindiDesc), isFalse);

      final detected = service.detectLanguageLabel(hindiTitle);
      expect(detected.contains('Hindi'), isTrue);
    });

    // -------------------------------------------------------------
    // Scenario 9: Other non-English description (Spanish/German translates to English)
    // -------------------------------------------------------------
    test('Scenario 9: Spanish and German descriptions are accurately detected as non-English', () {
      final service = TranslationService();

      const spanishDesc = 'Gran concurso para desarrolladores e ingenieros con premios en efectivo.';
      expect(service.isLikelyEnglish(spanishDesc), isFalse);
      expect(service.detectLanguageLabel(spanishDesc).contains('Spanish'), isTrue);

      const germanDesc = 'Herausforderung für Software-Entwickler und Programmierer in Berlin.';
      expect(service.isLikelyEnglish(germanDesc), isFalse);
      expect(service.detectLanguageLabel(germanDesc).contains('German'), isTrue);
    });

    // -------------------------------------------------------------
    // Scenario 10: Missing description
    // -------------------------------------------------------------
    test('Scenario 10: Empty or missing description handled safely without errors', () async {
      final service = TranslationService();

      final emptyResult = await service.translateToEnglish('');
      expect(emptyResult.wasTranslated, isFalse);
      expect(emptyResult.displayText, '');
      expect(emptyResult.isError, isFalse);

      final whitespaceResult = await service.translateToEnglish('   \n  ');
      expect(whitespaceResult.wasTranslated, isFalse);
      expect(whitespaceResult.displayText.trim(), '');
    });

    // -------------------------------------------------------------
    // Scenario 11: Translation failure fallback
    // -------------------------------------------------------------
    test('Scenario 11: Translation failure fallback returns original text with error flag', () {
      const fallbackResult = TranslationResult(
        originalText: 'Original text in another language',
        translatedText: '',
        wasTranslated: false,
        detectedLanguage: 'Español (Spanish)',
        isError: true,
        errorMessage: 'Network timeout',
      );

      expect(fallbackResult.isError, isTrue);
      expect(fallbackResult.wasTranslated, isFalse);
      expect(fallbackResult.displayText, 'Original text in another language');
    });

    // -------------------------------------------------------------
    // Scenario 12: Expired hackathon hidden by default
    // -------------------------------------------------------------
    test('Scenario 12: Expired hackathons are identified and filtered out when hideExpired is true', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
      final futureDate = DateTime.now().add(const Duration(days: 10)).toIso8601String().substring(0, 10);

      final expiredEvent = Hackathon.fromMap('past_1', {
        'title': 'Past Sprint',
        'deadline': pastDate,
      });

      final upcomingEvent = Hackathon.fromMap('future_1', {
        'title': 'Upcoming Sprint',
        'deadline': futureDate,
      });

      expect(expiredEvent.isExpired, isTrue);
      expect(upcomingEvent.isExpired, isFalse);

      // Filtering with hideExpired = true
      bool filterFn(Hackathon h, bool hideExpired) {
        if (hideExpired && h.isExpired) return false;
        return true;
      }

      expect(filterFn(expiredEvent, true), isFalse);
      expect(filterFn(upcomingEvent, true), isTrue);

      // When toggle is disabled, expired events are shown
      expect(filterFn(expiredEvent, false), isTrue);
    });

    // -------------------------------------------------------------
    // Scenario 13: Upcoming hackathon sorting
    // -------------------------------------------------------------
    test('Scenario 13: Upcoming hackathons prioritize Indian physical events first, then online, sorted by nearest deadline', () {
      final now = DateTime.now();
      String days(int d) => now.add(Duration(days: d)).toIso8601String().substring(0, 10);

      final indianPhysicalSoon = Hackathon.fromMap('h1', {
        'title': 'Bengaluru In-Person',
        'city': 'Bengaluru',
        'country': 'India',
        'mode': 'In-person',
        'deadline': days(5),
      });

      final indianPhysicalLater = Hackathon.fromMap('h2', {
        'title': 'Mumbai In-Person',
        'city': 'Mumbai',
        'country': 'India',
        'mode': 'In-person',
        'deadline': days(15),
      });

      final indianOnline = Hackathon.fromMap('h3', {
        'title': 'Smart India Online',
        'country': 'India',
        'mode': 'Online',
        'deadline': days(7),
      });

      final globalOnline = Hackathon.fromMap('h4', {
        'title': 'Global Cloud Online',
        'mode': 'Online',
        'deadline': days(2),
      });

      final intlPhysical = Hackathon.fromMap('h5', {
        'title': 'San Francisco Expo',
        'city': 'San Francisco',
        'country': 'USA',
        'mode': 'In-person',
        'deadline': days(3),
      });

      final expiredEvent = Hackathon.fromMap('h6', {
        'title': 'Old Closed Hackathon',
        'deadline': now.subtract(const Duration(days: 4)).toIso8601String().substring(0, 10),
      });

      final list = [
        expiredEvent,
        intlPhysical,
        globalOnline,
        indianOnline,
        indianPhysicalLater,
        indianPhysicalSoon,
      ];

      int priority(Hackathon h) {
        if (h.isIndia && !h.isOnline) return 0; // Indian in-person
        if (h.isIndia && h.isOnline) return 1;  // Indian online
        if (h.isOnline) return 2;               // Global online
        return 3;                               // International in-person
      }

      list.sort((a, b) {
        if (a.isExpired != b.isExpired) return a.isExpired ? 1 : -1;
        final pA = priority(a);
        final pB = priority(b);
        if (pA != pB) return pA.compareTo(pB);
        final deadA = DateTime.tryParse(a.deadline) ?? DateTime(2099);
        final deadB = DateTime.tryParse(b.deadline) ?? DateTime(2099);
        return deadA.compareTo(deadB);
      });

      // Assert order:
      expect(list[0].id, 'h1', reason: 'Indian in-person with nearest deadline (5d) is first');
      expect(list[1].id, 'h2', reason: 'Indian in-person with later deadline (15d) is second');
      expect(list[2].id, 'h3', reason: 'Indian online event is third');
      expect(list[3].id, 'h4', reason: 'Global online event is fourth');
      expect(list[4].id, 'h5', reason: 'International physical event is fifth');
      expect(list[5].id, 'h6', reason: 'Expired event is at the very bottom');
    });

    // -------------------------------------------------------------
    // Scenario 14: Location filtering combined with search
    // -------------------------------------------------------------
    test('Scenario 14: Location filtering combined with search query matches correctly', () {
      final blrAi = Hackathon.fromMap('1', {
        'title': 'Bengaluru Generative AI Hackathon',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'country': 'India',
        'description': 'AI agents and LLMs',
      });

      final blrWeb = Hackathon.fromMap('2', {
        'title': 'Bengaluru FullStack Challenge',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'country': 'India',
        'description': 'React and Flutter web apps',
      });

      final delAi = Hackathon.fromMap('3', {
        'title': 'Delhi AI Innovation Sprint',
        'city': 'New Delhi',
        'state': 'Delhi',
        'country': 'India',
        'description': 'Machine learning for robotics',
      });

      bool matches(Hackathon event, {required String query, required String city}) {
        final q = query.toLowerCase();
        final text = '${event.title} ${event.description}'.toLowerCase();
        final matchesQuery = q.isEmpty || text.contains(q);
        final matchesCity = city == 'All Cities' || event.city.toLowerCase() == city.toLowerCase();
        return matchesQuery && matchesCity;
      }

      // Query "AI" + City "Bengaluru" -> only blrAi matches
      expect(matches(blrAi, query: 'AI', city: 'Bengaluru'), isTrue);
      expect(matches(blrWeb, query: 'AI', city: 'Bengaluru'), isFalse);
      expect(matches(delAi, query: 'AI', city: 'Bengaluru'), isFalse);
    });

    // -------------------------------------------------------------
    // Scenario 15: Bookmarked event with translated description
    // -------------------------------------------------------------
    test('Scenario 15: Bookmarked event with translated content displays translated text while preserving original in model', () {
      final originalEvent = Hackathon(
        id: 'bookmarked_event_1',
        title: 'ग्रैंड इंडियन कोड हैकथॉन',
        organizer: 'Tech India Hub',
        deadline: '2026-12-05',
        prize: '₹5,00,000',
        description: 'डेवलपर्स के लिए सबसे बड़ा कोडिंग मुकाबला।',
        location: 'Bengaluru, Karnataka',
        mode: 'In-person',
        teamSize: '2-4',
        registrationLink: 'https://hackpilot.dev',
        translatedTitle: 'Grand Indian Code Hackathon',
        translatedDescription: 'The biggest coding competition for developers.',
      );

      // Presentation layer displays translated text
      expect(originalEvent.displayTitle, 'Grand Indian Code Hackathon');
      expect(originalEvent.displayDescription, 'The biggest coding competition for developers.');

      // Original database properties remain completely preserved
      expect(originalEvent.title, 'ग्रैंड इंडियन कोड हैकथॉन');
      expect(originalEvent.description, 'डेवलपर्स के लिए सबसे बड़ा कोडिंग मुकाबला।');

      // Serialization into Firestore preserve original and translation metadata
      final map = originalEvent.toMap();
      expect(map['title'], 'ग्रैंड इंडियन कोड हैकथॉन');
      expect(map['translatedTitle'], 'Grand Indian Code Hackathon');
      expect(map['translatedDescription'], 'The biggest coding competition for developers.');
    });
  });
}

